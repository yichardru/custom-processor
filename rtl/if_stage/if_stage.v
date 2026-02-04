`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2026 04:36:09 PM
// Design Name: 
// Module Name: if_stage
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


module if_stage (
    input clk,
    input reset,
    input pc_write_en, // from hazard unit (stall control)
    input [31:0] branch_target, // computed in EX stage
    input branch_taken, // 1 if branch should be taken
    output [31:0] instr_out, // fetched instruction
    output [31:0] pc_out // PC of current instruction
);


    // Internal wires
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4;
    
    
    // Instantiate PC module
    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .pc_write_en(pc_write_en),
        .next_pc(pc_next),
        .pc_out(pc_current)
    );
    
    // PC + 4
    assign pc_plus4 = pc_current + 4;
    
    // Next PC selection logic
    assign pc_next = (branch_taken) ? branch_target : pc_plus4;
    
    // Instruction Memory 
    instr_memory instr_mem_inst (
        .addr(pc_current),
        .instr(instr_out)
    );
    assign pc_out = pc_current;

endmodule