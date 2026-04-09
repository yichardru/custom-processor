`timescale 1ns / 1ps

module if_id_reg (
    input         clk,
    input         reset,
    input         write_en,   // 0 = stall (hold values)
    input         flush,      // 1 = flush (insert NOP)
    input  [31:0] if_pc,
    input  [31:0] if_instr,
    output reg [31:0] id_pc,
    output reg [31:0] id_instr
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            id_pc    <= 32'b0;
            id_instr <= 32'h00000013; // NOP: ADDI x0, x0, 0
        end else if (write_en) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
        end
        // else: hold (stall)
    end

endmodule
