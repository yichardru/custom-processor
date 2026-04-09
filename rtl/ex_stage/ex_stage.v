`timescale 1ns / 1ps

module ex_stage (
    // From ID/EX register
    input  [31:0] rs1_data,
    input  [31:0] rs2_data,
    input  [31:0] imm,
    input  [31:0] pc,
    input  [2:0]  funct3,
    input         funct7_bit5,
    input  [1:0]  alu_op,
    input         alu_src,        // 0: rs2, 1: imm
    input  [1:0]  alu_src_a,      // 00: rs1, 01: PC, 10: zero
    input         branch,
    input         jal,
    input         jalr,
    // Forwarding controls
    input  [1:0]  forward_a,
    input  [1:0]  forward_b,
    input  [31:0] ex_mem_alu_result,
    input  [31:0] wb_data,
    // Outputs
    output [31:0] alu_result,
    output [31:0] rs2_forwarded,
    output        branch_taken,
    output [31:0] branch_target,
    output [31:0] pc_plus4
);

    // Forwarding muxes
    wire [31:0] fwd_rs1 = (forward_a == 2'b10) ? ex_mem_alu_result :
                          (forward_a == 2'b01) ? wb_data :
                          rs1_data;

    wire [31:0] fwd_rs2 = (forward_b == 2'b10) ? ex_mem_alu_result :
                          (forward_b == 2'b01) ? wb_data :
                          rs2_data;

    assign rs2_forwarded = fwd_rs2;

    // ALU operand A selection
    wire [31:0] alu_a = (alu_src_a == 2'b01) ? pc :
                        (alu_src_a == 2'b10) ? 32'b0 :
                        fwd_rs1;

    // ALU operand B selection
    wire [31:0] alu_b = alu_src ? imm : fwd_rs2;

    // ALU control
    wire [3:0] alu_ctrl;
    alu_control alu_ctrl_inst (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7_bit5(funct7_bit5),
        .alu_ctrl(alu_ctrl)
    );

    // ALU
    alu alu_inst (
        .a(alu_a),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result)
    );

    // Branch unit (uses forwarded register values for comparison)
    branch_unit bu (
        .rs1_data(fwd_rs1),
        .rs2_data(fwd_rs2),
        .pc(pc),
        .imm(imm),
        .funct3(funct3),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );

    // PC + 4 for JAL/JALR writeback
    assign pc_plus4 = pc + 32'd4;

endmodule
