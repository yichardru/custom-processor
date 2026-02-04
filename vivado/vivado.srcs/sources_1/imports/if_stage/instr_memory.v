`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2026 04:20:39 PM
// Design Name: 
// Module Name: instr_memory
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


module instr_memory (
    input [31:0] addr,
    output [31:0] instr
);

reg [31:0] memory [0:255]; // 256 words or 1KB dummy memory

initial begin
    $display("Loading program.mem ...");
    $readmemh("program.mem", memory);
end


assign instr = memory[addr[9:2]];


endmodule
