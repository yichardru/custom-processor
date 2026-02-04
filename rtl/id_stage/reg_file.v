`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2026 04:55:20 PM
// Design Name: 
// Module Name: reg_file
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

module reg_file (
    input clk,
    input reset,
    input we,              // Write enable
    input [4:0]  rs1,             // Read address 1
    input [4:0]  rs2,             // Read address 2
    input [4:0]  rd,              // Write address
    input [31:0] wd,              // Write data
    output [31:0] rd1,             // Read data 1
    output [31:0] rd2              // Read data 2
);

    reg [31:0] regs[0:31];

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (we && rd != 5'd0) begin
            regs[rd] <= wd;  // x0 is hardwired to 0
        end
    end

    // Combinational reads
    assign rd1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];

endmodule
