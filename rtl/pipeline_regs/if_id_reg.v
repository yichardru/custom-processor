`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: if_id_reg
// Description: IF/ID pipeline register.
//   flush   = 1  →  insert NOP (used when a branch is taken)
//   write_en= 0  →  hold current value (used during a load-use stall)
//////////////////////////////////////////////////////////////////////////////////

module if_id_reg (
    input         clk,
    input         reset,
    input         flush,
    input         write_en,

    // Inputs from IF stage
    input  [31:0] instr_in,
    input  [31:0] pc_in,

    // Outputs to ID stage
    output reg [31:0] instr_out,
    output reg [31:0] pc_out
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            instr_out <= 32'h00000013; // NOP: ADDI x0, x0, 0
            pc_out    <= 32'b0;
        end else if (write_en) begin
            instr_out <= instr_in;
            pc_out    <= pc_in;
        end
        // else: hold (stall)
    end

endmodule
