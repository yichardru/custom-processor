`timescale 1ns / 1ps

module branch_unit (
    input  [31:0] rs1_data,       // forwarded rs1
    input  [31:0] rs2_data,       // forwarded rs2
    input  [31:0] pc,
    input  [31:0] imm,
    input  [2:0]  funct3,
    input         branch,
    input         jal,
    input         jalr,
    output        branch_taken,
    output [31:0] branch_target
);

    // Branch condition evaluation
    wire eq  = (rs1_data == rs2_data);
    wire lt  = ($signed(rs1_data) < $signed(rs2_data));
    wire ltu = (rs1_data < rs2_data);

    reg branch_cond;
    always @(*) begin
        case (funct3)
            3'b000:  branch_cond = eq;   // BEQ
            3'b001:  branch_cond = ~eq;  // BNE
            3'b100:  branch_cond = lt;   // BLT
            3'b101:  branch_cond = ~lt;  // BGE
            3'b110:  branch_cond = ltu;  // BLTU
            3'b111:  branch_cond = ~ltu; // BGEU
            default: branch_cond = 1'b0;
        endcase
    end

    assign branch_taken = (branch & branch_cond) | jal | jalr;

    // Target address: JALR uses rs1 + imm (with bit 0 cleared), others use PC + imm
    assign branch_target = jalr ? ((rs1_data + imm) & ~32'd1) : (pc + imm);

endmodule
