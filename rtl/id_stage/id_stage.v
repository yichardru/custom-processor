`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: id_stage
// Description: Instruction Decode stage.
//   - Reads the register file (two read ports, one write port from WB).
//   - Generates the immediate value.
//   - Produces all control signals for the ID/EX pipeline register.
//
// Write-before-read: reg_file bypasses the write data on a same-cycle
// collision so that the WB→ID data path needs no additional stall.
//////////////////////////////////////////////////////////////////////////////////

module id_stage (
    input         clk,
    input         reset,

    // From IF/ID pipeline register
    input  [31:0] instr,
    input  [31:0] pc,

    // Write-back port (from WB stage)
    input         wb_reg_write,
    input  [4:0]  wb_rd,
    input  [31:0] wb_wd,

    // Register-file read data (forwarded to ID/EX register)
    output [31:0] rs1_data,
    output [31:0] rs2_data,

    // Decoded fields
    output [31:0] imm,
    output [4:0]  rs1_addr,
    output [4:0]  rs2_addr,
    output [4:0]  rd_addr,
    output [2:0]  funct3,
    output        funct7b5,  // instr[30], selects SUB / SRA

    // Control signals
    output        reg_write,
    output        alu_src_b,
    output        alu_src_a,
    output        mem_read,
    output        mem_write,
    output [1:0]  mem_to_reg,
    output        branch,
    output        jump,
    output        jalr,
    output [1:0]  alu_op
);

    // Decode instruction fields
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];
    assign funct3   = instr[14:12];
    assign funct7b5 = instr[30];

    // Register file
    reg_file rf (
        .clk   (clk),
        .reset (reset),
        .we    (wb_reg_write),
        .rs1   (rs1_addr),
        .rs2   (rs2_addr),
        .rd    (wb_rd),
        .wd    (wb_wd),
        .rd1   (rs1_data),
        .rd2   (rs2_data)
    );

    // Immediate generator
    imm_gen ig (
        .instr (instr),
        .imm   (imm)
    );

    // Control unit
    control_unit cu (
        .opcode    (instr[6:0]),
        .reg_write (reg_write),
        .alu_src_b (alu_src_b),
        .alu_src_a (alu_src_a),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .mem_to_reg(mem_to_reg),
        .branch    (branch),
        .jump      (jump),
        .jalr      (jalr),
        .alu_op    (alu_op)
    );

endmodule
