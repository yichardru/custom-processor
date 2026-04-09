`timescale 1ns / 1ps

module id_stage (
    input         clk,
    input         reset,
    // From IF/ID register
    input  [31:0] instr,
    input  [31:0] pc,
    // Writeback from WB
    input         wb_reg_write,
    input  [4:0]  wb_rd,
    input  [31:0] wb_data,
    // Outputs to ID/EX register
    output [31:0] rs1_data,
    output [31:0] rs2_data,
    output [31:0] imm,
    output [4:0]  rs1_addr,
    output [4:0]  rs2_addr,
    output [4:0]  rd_addr,
    output [2:0]  funct3,
    output        funct7_bit5,
    // Control signals
    output        reg_write,
    output        mem_read,
    output        mem_write,
    output        alu_src,
    output [1:0]  alu_op,
    output        branch,
    output        jal,
    output        jalr,
    output [1:0]  mem_to_reg,
    output [1:0]  alu_src_a
);

    // Instruction field extraction
    wire [6:0] opcode = instr[6:0];
    assign rd_addr     = instr[11:7];
    assign funct3      = instr[14:12];
    assign rs1_addr    = instr[19:15];
    assign rs2_addr    = instr[24:20];
    assign funct7_bit5 = instr[30];

    // Register File
    reg_file rf (
        .clk(clk),
        .reset(reset),
        .we(wb_reg_write),
        .rs1(rs1_addr),
        .rs2(rs2_addr),
        .rd(wb_rd),
        .wd(wb_data),
        .rd1(rs1_data),
        .rd2(rs2_data)
    );

    // Immediate Generator
    imm_gen ig (
        .instr(instr),
        .imm(imm)
    );

    // Control Unit
    control_unit cu (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .mem_to_reg(mem_to_reg),
        .alu_src_a(alu_src_a)
    );

endmodule
