`timescale 1ns / 1ps

module wb_stage (
    input  [1:0]  mem_to_reg,
    input  [31:0] alu_result,
    input  [31:0] read_data,
    input  [31:0] pc_plus4,
    output [31:0] wb_data
);

    // Writeback mux: 00 = ALU result, 01 = memory data, 10 = PC+4
    assign wb_data = (mem_to_reg == 2'b01) ? read_data :
                     (mem_to_reg == 2'b10) ? pc_plus4 :
                     alu_result;

endmodule
