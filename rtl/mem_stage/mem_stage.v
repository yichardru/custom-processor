`timescale 1ns / 1ps

module mem_stage (
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [2:0]  funct3,
    input  [31:0] alu_result,     // address
    input  [31:0] write_data,     // rs2 data for stores
    output [31:0] read_data
);

    data_memory dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .addr(alu_result),
        .write_data(write_data),
        .read_data(read_data)
    );

endmodule
