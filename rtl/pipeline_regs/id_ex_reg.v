`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: id_ex_reg
// Description: ID/EX pipeline register.
//   flush = 1  →  zero out all control signals (NOP bubble).
//                 Used for load-use stalls and branch flushes.
//////////////////////////////////////////////////////////////////////////////////

module id_ex_reg (
    input         clk,
    input         reset,
    input         flush,

    // Data inputs from ID stage
    input  [31:0] rs1_data_in,
    input  [31:0] rs2_data_in,
    input  [31:0] imm_in,
    input  [31:0] pc_in,
    input  [31:0] pc_plus4_in,
    input  [4:0]  rs1_addr_in,
    input  [4:0]  rs2_addr_in,
    input  [4:0]  rd_addr_in,
    input  [2:0]  funct3_in,
    input         funct7b5_in,

    // Control inputs from ID stage
    input         reg_write_in,
    input         alu_src_b_in,
    input         alu_src_a_in,
    input         mem_read_in,
    input         mem_write_in,
    input  [1:0]  mem_to_reg_in,
    input         branch_in,
    input         jump_in,
    input         jalr_in,
    input  [1:0]  alu_op_in,

    // Data outputs to EX stage
    output reg [31:0] rs1_data_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] imm_out,
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus4_out,
    output reg [4:0]  rs1_addr_out,
    output reg [4:0]  rs2_addr_out,
    output reg [4:0]  rd_addr_out,
    output reg [2:0]  funct3_out,
    output reg        funct7b5_out,

    // Control outputs to EX stage
    output reg        reg_write_out,
    output reg        alu_src_b_out,
    output reg        alu_src_a_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg [1:0]  mem_to_reg_out,
    output reg        branch_out,
    output reg        jump_out,
    output reg        jalr_out,
    output reg [1:0]  alu_op_out
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            // Insert NOP bubble – zero out all control and data fields
            rs1_data_out  <= 32'b0;
            rs2_data_out  <= 32'b0;
            imm_out       <= 32'b0;
            pc_out        <= 32'b0;
            pc_plus4_out  <= 32'b0;
            rs1_addr_out  <= 5'b0;
            rs2_addr_out  <= 5'b0;
            rd_addr_out   <= 5'b0;
            funct3_out    <= 3'b0;
            funct7b5_out  <= 1'b0;
            reg_write_out <= 1'b0;
            alu_src_b_out <= 1'b0;
            alu_src_a_out <= 1'b0;
            mem_read_out  <= 1'b0;
            mem_write_out <= 1'b0;
            mem_to_reg_out<= 2'b0;
            branch_out    <= 1'b0;
            jump_out      <= 1'b0;
            jalr_out      <= 1'b0;
            alu_op_out    <= 2'b0;
        end else begin
            rs1_data_out  <= rs1_data_in;
            rs2_data_out  <= rs2_data_in;
            imm_out       <= imm_in;
            pc_out        <= pc_in;
            pc_plus4_out  <= pc_plus4_in;
            rs1_addr_out  <= rs1_addr_in;
            rs2_addr_out  <= rs2_addr_in;
            rd_addr_out   <= rd_addr_in;
            funct3_out    <= funct3_in;
            funct7b5_out  <= funct7b5_in;
            reg_write_out <= reg_write_in;
            alu_src_b_out <= alu_src_b_in;
            alu_src_a_out <= alu_src_a_in;
            mem_read_out  <= mem_read_in;
            mem_write_out <= mem_write_in;
            mem_to_reg_out<= mem_to_reg_in;
            branch_out    <= branch_in;
            jump_out      <= jump_in;
            jalr_out      <= jalr_in;
            alu_op_out    <= alu_op_in;
        end
    end

endmodule
