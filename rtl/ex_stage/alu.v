`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: alu
// Description: 32-bit ALU supporting the full RV32I operation set.
//
// Operations (alu_ctrl):
//   4'b0000  ADD   result = a + b
//   4'b0001  SUB   result = a - b
//   4'b0010  AND   result = a & b
//   4'b0011  OR    result = a | b
//   4'b0100  XOR   result = a ^ b
//   4'b0101  SLL   result = a << b[4:0]
//   4'b0110  SRL   result = a >> b[4:0]   (logical)
//   4'b0111  SRA   result = a >>> b[4:0]  (arithmetic)
//   4'b1000  SLT   result = (signed a < signed b) ? 1 : 0
//   4'b1001  SLTU  result = (a < b) ? 1 : 0  (unsigned)
//   4'b1010  PASSB result = b
//
// Flags (used by EX stage branch logic):
//   zero     – result == 0          (BEQ / BNE)
//   negative – result[31]           (BLT / BGE via N XOR V)
//   overflow – signed overflow      (BLT / BGE)
//   carry    – 1 when a >= b (unsigned) for SUB; carry-out for ADD
//              (BLTU: taken when carry==0; BGEU: taken when carry==1)
//////////////////////////////////////////////////////////////////////////////////

module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result,
    output        zero,
    output        negative,
    output reg    overflow,
    output reg    carry
);

    reg [32:0] tmp; // 33-bit to capture carry/borrow

    assign zero     = (result == 32'b0);
    assign negative = result[31];

    always @(*) begin
        tmp      = 33'b0;
        result   = 32'b0;
        overflow = 1'b0;
        carry    = 1'b0;

        case (alu_ctrl)
            4'b0000: begin // ADD
                tmp      = {1'b0, a} + {1'b0, b};
                result   = tmp[31:0];
                carry    = tmp[32];
                overflow = (~a[31] & ~b[31] & result[31]) |
                           ( a[31] &  b[31] & ~result[31]);
            end

            4'b0001: begin // SUB  (a - b  =  a + ~b + 1)
                tmp      = {1'b0, a} + {1'b0, ~b} + 33'd1;
                result   = tmp[31:0];
                carry    = tmp[32]; // 1 when a >= b (unsigned) – no borrow
                overflow = (~a[31] &  b[31] & result[31]) |
                           ( a[31] & ~b[31] & ~result[31]);
            end

            4'b0010: result = a & b;   // AND
            4'b0011: result = a | b;   // OR
            4'b0100: result = a ^ b;   // XOR

            4'b0101: result = a << b[4:0];                   // SLL
            4'b0110: result = a >> b[4:0];                   // SRL
            4'b0111: result = $signed(a) >>> b[4:0];         // SRA

            4'b1000: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1001: result = (a < b)                 ? 32'd1 : 32'd0;   // SLTU

            4'b1010: result = b; // PASSB – used for LUI

            default: result = 32'b0;
        endcase
    end

endmodule
