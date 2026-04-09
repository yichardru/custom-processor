`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: mem_stage
// Description: Memory access stage.  Wraps data_memory and passes through
//              non-memory signals to the MEM/WB pipeline register.
//////////////////////////////////////////////////////////////////////////////////

module mem_stage (
    input         clk,

    // From EX/MEM pipeline register
    input  [31:0] alu_result,
    input  [31:0] rs2_data,
    input  [4:0]  rd_addr,
    input  [31:0] pc_plus4,
    input  [2:0]  funct3,
    input         mem_read,
    input         mem_write,

    // Outputs to MEM/WB pipeline register
    output [31:0] alu_result_out,
    output [31:0] mem_data,
    output [4:0]  rd_addr_out,
    output [31:0] pc_plus4_out
);

    // Pass-through signals
    assign alu_result_out = alu_result;
    assign rd_addr_out    = rd_addr;
    assign pc_plus4_out   = pc_plus4;

    // Data memory instance
    data_memory dmem (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (alu_result),
        .write_data (rs2_data),
        .funct3     (funct3),
        .read_data  (mem_data)
    );

endmodule
