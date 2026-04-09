`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ex_mem_reg
// Description: EX/MEM pipeline register.
//              Flushes to zeros (NOP) on reset.
//////////////////////////////////////////////////////////////////////////////////

module ex_mem_reg (
    input         clk,
    input         reset,

    // Data inputs from EX stage
    input  [31:0] alu_result_in,
    input  [31:0] rs2_data_in,
    input  [4:0]  rd_addr_in,
    input  [31:0] pc_plus4_in,
    input  [2:0]  funct3_in,

    // Control inputs from EX stage
    input         reg_write_in,
    input         mem_read_in,
    input         mem_write_in,
    input  [1:0]  mem_to_reg_in,

    // Data outputs to MEM stage
    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [4:0]  rd_addr_out,
    output reg [31:0] pc_plus4_out,
    output reg [2:0]  funct3_out,

    // Control outputs to MEM stage
    output reg        reg_write_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg [1:0]  mem_to_reg_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_result_out  <= 32'b0;
            rs2_data_out    <= 32'b0;
            rd_addr_out     <= 5'b0;
            pc_plus4_out    <= 32'b0;
            funct3_out      <= 3'b0;
            reg_write_out   <= 1'b0;
            mem_read_out    <= 1'b0;
            mem_write_out   <= 1'b0;
            mem_to_reg_out  <= 2'b0;
        end else begin
            alu_result_out  <= alu_result_in;
            rs2_data_out    <= rs2_data_in;
            rd_addr_out     <= rd_addr_in;
            pc_plus4_out    <= pc_plus4_in;
            funct3_out      <= funct3_in;
            reg_write_out   <= reg_write_in;
            mem_read_out    <= mem_read_in;
            mem_write_out   <= mem_write_in;
            mem_to_reg_out  <= mem_to_reg_in;
        end
    end

endmodule
