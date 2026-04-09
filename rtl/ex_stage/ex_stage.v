`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ex_stage
// Description: Execute stage.
//   - Applies data-forwarding muxes for rs1 / rs2.
//   - Selects ALU inputs (rs1 or PC, rs2 or immediate).
//   - Computes the ALU result and branch/jump condition.
//   - Produces branch_taken and branch_target for the IF stage.
//   - Passes alu_result and (forwarded) rs2_data to the EX/MEM register.
//
// Forwarding encoding (forwardA / forwardB):
//   2'b00  – use register-file value from ID/EX
//   2'b01  – forward from MEM/WB  (wb_data)
//   2'b10  – forward from EX/MEM  (ex_mem_alu_result)
//////////////////////////////////////////////////////////////////////////////////

module ex_stage (
    // From ID/EX pipeline register
    input  [31:0] rs1_data,
    input  [31:0] rs2_data,
    input  [31:0] imm,
    input  [31:0] pc,
    input  [4:0]  rd_addr,
    input  [2:0]  funct3,
    input         funct7b5,
    input         alu_src_a,
    input         alu_src_b,
    input         branch,
    input         jump,
    input         jalr,
    input  [1:0]  alu_op,

    // Forwarding control (from hazard unit)
    input  [1:0]  forwardA,
    input  [1:0]  forwardB,

    // Forwarding data sources
    input  [31:0] ex_mem_alu_result, // EX/MEM ALU result
    input  [31:0] wb_data,           // MEM/WB write-back data

    // Outputs to EX/MEM register
    output [31:0] alu_result,
    output [31:0] rs2_fwd_data,  // (possibly forwarded) rs2 for stores
    output [4:0]  rd_addr_out,

    // Branch/jump feedback to IF stage
    output        branch_taken,
    output [31:0] branch_target
);

    // ------------------------------------------------------------------ //
    // Forwarding muxes
    // ------------------------------------------------------------------ //
    wire [31:0] fwd_a =
        (forwardA == 2'b10) ? ex_mem_alu_result :
        (forwardA == 2'b01) ? wb_data           :
                              rs1_data;

    wire [31:0] fwd_b =
        (forwardB == 2'b10) ? ex_mem_alu_result :
        (forwardB == 2'b01) ? wb_data           :
                              rs2_data;

    // rs2_fwd_data carries the (possibly forwarded) store value forward
    assign rs2_fwd_data = fwd_b;
    assign rd_addr_out  = rd_addr;

    // ------------------------------------------------------------------ //
    // ALU input selection
    // ------------------------------------------------------------------ //
    wire [31:0] alu_in_a = alu_src_a ? pc    : fwd_a;
    wire [31:0] alu_in_b = alu_src_b ? imm   : fwd_b;

    // ------------------------------------------------------------------ //
    // ALU control + ALU
    // ------------------------------------------------------------------ //
    wire [3:0] alu_ctrl_sig;

    alu_ctrl alu_ctrl_inst (
        .alu_op       (alu_op),
        .funct3       (funct3),
        .funct7b5     (funct7b5),
        .opcode5      (alu_src_b ? 1'b0 : 1'b1), // 0 = I-type, 1 = R-type
        .alu_ctrl_out (alu_ctrl_sig)
    );

    wire        alu_zero;
    wire        alu_neg;
    wire        alu_ovf;
    wire        alu_carry;

    alu alu_inst (
        .a        (alu_in_a),
        .b        (alu_in_b),
        .alu_ctrl (alu_ctrl_sig),
        .result   (alu_result),
        .zero     (alu_zero),
        .negative (alu_neg),
        .overflow (alu_ovf),
        .carry    (alu_carry)
    );

    // ------------------------------------------------------------------ //
    // Branch condition evaluation
    // ------------------------------------------------------------------ //
    reg branch_cond;

    always @(*) begin
        case (funct3)
            3'b000: branch_cond = alu_zero;             // BEQ
            3'b001: branch_cond = ~alu_zero;            // BNE
            3'b100: branch_cond = alu_neg ^ alu_ovf;    // BLT  (signed)
            3'b101: branch_cond = ~(alu_neg ^ alu_ovf); // BGE  (signed)
            3'b110: branch_cond = ~alu_carry;           // BLTU (carry=0 ⟹ a<b unsigned)
            3'b111: branch_cond = alu_carry;            // BGEU (carry=1 ⟹ a>=b unsigned)
            default: branch_cond = 1'b0;
        endcase
    end

    // ------------------------------------------------------------------ //
    // Branch / jump target computation
    // ------------------------------------------------------------------ //
    // Branch target is always PC + sign-extended imm
    wire [31:0] pc_plus_imm = pc + imm;

    // For JAL:  alu_result = PC+imm  (alu_src_a=1 selects PC, alu_src_b=1 selects imm)
    // For JALR: alu_result = rs1+imm, then bit 0 must be cleared
    wire [31:0] jump_target  = jalr ? (alu_result & 32'hFFFFFFFE) : alu_result;

    assign branch_target = branch ? pc_plus_imm : jump_target;
    assign branch_taken  = (branch & branch_cond) | jump;

endmodule
