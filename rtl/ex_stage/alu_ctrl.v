`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: alu_ctrl
// Description: Translates the 2-bit alu_op from the control unit and the
//              instruction's funct3/funct7 fields into a 4-bit ALU operation
//              code consumed by the ALU.
//
// alu_op:
//   2'b00  force ADD   (loads, stores, AUIPC, JAL, JALR)
//   2'b01  force SUB   (branch comparison)
//   2'b10  use funct   (R-type and I-type ALU)
//   2'b11  pass B      (LUI)
//
// opcode5 (= instr[5]):
//   1 = R-type: funct3==3'b000 can be ADD or SUB (selected by funct7b5)
//   0 = I-type: funct3==3'b000 is always ADDI (ignore funct7b5)
//
// ALU operation codes (4-bit):
//   4'b0000  ADD
//   4'b0001  SUB
//   4'b0010  AND
//   4'b0011  OR
//   4'b0100  XOR
//   4'b0101  SLL
//   4'b0110  SRL
//   4'b0111  SRA
//   4'b1000  SLT  (signed less-than)
//   4'b1001  SLTU (unsigned less-than)
//   4'b1010  PASSB (pass operand B – used for LUI)
//////////////////////////////////////////////////////////////////////////////////

module alu_ctrl (
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input        funct7b5,  // instr[30]
    input        opcode5,   // instr[5]
    output reg [3:0] alu_ctrl_out
);

    // Symbolic constants matching the ALU
    localparam ADD   = 4'b0000;
    localparam SUB   = 4'b0001;
    localparam AND   = 4'b0010;
    localparam OR    = 4'b0011;
    localparam XOR   = 4'b0100;
    localparam SLL   = 4'b0101;
    localparam SRL   = 4'b0110;
    localparam SRA   = 4'b0111;
    localparam SLT   = 4'b1000;
    localparam SLTU  = 4'b1001;
    localparam PASSB = 4'b1010;

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl_out = ADD;
            2'b01: alu_ctrl_out = SUB;
            2'b11: alu_ctrl_out = PASSB;

            2'b10: begin
                case (funct3)
                    3'b000: alu_ctrl_out = (funct7b5 && opcode5) ? SUB : ADD;
                    3'b001: alu_ctrl_out = SLL;
                    3'b010: alu_ctrl_out = SLT;
                    3'b011: alu_ctrl_out = SLTU;
                    3'b100: alu_ctrl_out = XOR;
                    3'b101: alu_ctrl_out = funct7b5 ? SRA : SRL;
                    3'b110: alu_ctrl_out = OR;
                    3'b111: alu_ctrl_out = AND;
                    default: alu_ctrl_out = ADD;
                endcase
            end

            default: alu_ctrl_out = ADD;
        endcase
    end

endmodule
