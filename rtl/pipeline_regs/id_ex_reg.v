`timescale 1ns / 1ps

module id_ex_reg (
    input         clk,
    input         reset,
    input         flush,          // 1 = insert bubble (zero control signals)
    // Control signals in
    input         id_reg_write,
    input         id_mem_read,
    input         id_mem_write,
    input         id_alu_src,
    input  [1:0]  id_alu_op,
    input         id_branch,
    input         id_jal,
    input         id_jalr,
    input  [1:0]  id_mem_to_reg,
    input  [1:0]  id_alu_src_a,
    // Data in
    input  [31:0] id_rs1_data,
    input  [31:0] id_rs2_data,
    input  [31:0] id_imm,
    input  [31:0] id_pc,
    input  [2:0]  id_funct3,
    input         id_funct7_bit5,
    input  [4:0]  id_rs1_addr,
    input  [4:0]  id_rs2_addr,
    input  [4:0]  id_rd_addr,
    // Control signals out
    output reg        ex_reg_write,
    output reg        ex_mem_read,
    output reg        ex_mem_write,
    output reg        ex_alu_src,
    output reg [1:0]  ex_alu_op,
    output reg        ex_branch,
    output reg        ex_jal,
    output reg        ex_jalr,
    output reg [1:0]  ex_mem_to_reg,
    output reg [1:0]  ex_alu_src_a,
    // Data out
    output reg [31:0] ex_rs1_data,
    output reg [31:0] ex_rs2_data,
    output reg [31:0] ex_imm,
    output reg [31:0] ex_pc,
    output reg [2:0]  ex_funct3,
    output reg        ex_funct7_bit5,
    output reg [4:0]  ex_rs1_addr,
    output reg [4:0]  ex_rs2_addr,
    output reg [4:0]  ex_rd_addr
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            // Zero all control signals (NOP bubble)
            ex_reg_write  <= 1'b0;
            ex_mem_read   <= 1'b0;
            ex_mem_write  <= 1'b0;
            ex_alu_src    <= 1'b0;
            ex_alu_op     <= 2'b00;
            ex_branch     <= 1'b0;
            ex_jal        <= 1'b0;
            ex_jalr       <= 1'b0;
            ex_mem_to_reg <= 2'b00;
            ex_alu_src_a  <= 2'b00;
            // Zero data
            ex_rs1_data    <= 32'b0;
            ex_rs2_data    <= 32'b0;
            ex_imm         <= 32'b0;
            ex_pc          <= 32'b0;
            ex_funct3      <= 3'b0;
            ex_funct7_bit5 <= 1'b0;
            ex_rs1_addr    <= 5'b0;
            ex_rs2_addr    <= 5'b0;
            ex_rd_addr     <= 5'b0;
        end else begin
            ex_reg_write  <= id_reg_write;
            ex_mem_read   <= id_mem_read;
            ex_mem_write  <= id_mem_write;
            ex_alu_src    <= id_alu_src;
            ex_alu_op     <= id_alu_op;
            ex_branch     <= id_branch;
            ex_jal        <= id_jal;
            ex_jalr       <= id_jalr;
            ex_mem_to_reg <= id_mem_to_reg;
            ex_alu_src_a  <= id_alu_src_a;
            ex_rs1_data    <= id_rs1_data;
            ex_rs2_data    <= id_rs2_data;
            ex_imm         <= id_imm;
            ex_pc          <= id_pc;
            ex_funct3      <= id_funct3;
            ex_funct7_bit5 <= id_funct7_bit5;
            ex_rs1_addr    <= id_rs1_addr;
            ex_rs2_addr    <= id_rs2_addr;
            ex_rd_addr     <= id_rd_addr;
        end
    end

endmodule
