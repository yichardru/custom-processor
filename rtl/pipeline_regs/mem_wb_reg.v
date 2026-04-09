`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: mem_wb_reg
// Description: MEM/WB pipeline register.
//              Flushes to zeros (NOP) on reset.
//////////////////////////////////////////////////////////////////////////////////

module mem_wb_reg (
    input         clk,
    input         reset,

    // Data inputs from MEM stage
    input  [31:0] alu_result_in,
    input  [31:0] mem_data_in,
    input  [4:0]  rd_addr_in,
    input  [31:0] pc_plus4_in,

    // Control inputs from MEM stage
    input         reg_write_in,
    input  [1:0]  mem_to_reg_in,

    // Data outputs to WB stage
    output reg [31:0] alu_result_out,
    output reg [31:0] mem_data_out,
    output reg [4:0]  rd_addr_out,
    output reg [31:0] pc_plus4_out,

    // Control outputs to WB stage
    output reg        reg_write_out,
    output reg [1:0]  mem_to_reg_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_result_out <= 32'b0;
            mem_data_out   <= 32'b0;
            rd_addr_out    <= 5'b0;
            pc_plus4_out   <= 32'b0;
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 2'b0;
        end else begin
            alu_result_out <= alu_result_in;
            mem_data_out   <= mem_data_in;
            rd_addr_out    <= rd_addr_in;
            pc_plus4_out   <= pc_plus4_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end

endmodule
