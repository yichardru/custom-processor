`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2026 04:12:33 PM
// Design Name: program counter
// Module Name: pc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pc(
    input clk,
    input reset,
    input pc_write_en,
    input[31:0] next_pc,
    output[31:0] pc_out
    );
    
    reg[31:0] pc_reg;

    assign pc_out = pc_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_reg <= 32'h00000000;
        else if (pc_write_en)
            pc_reg <= next_pc;
        // else: hold value (stall)
    end 
    
endmodule
