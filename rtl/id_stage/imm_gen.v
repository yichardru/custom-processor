`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: imm_gen
// Description: Sign-extends immediates for all RV32I instruction formats.
//
// Supported formats and opcode encoding:
//   I-type ALU / JALR : 0010011 / 1100111
//   Load               : 0000011
//   S-type             : 0100011
//   B-type             : 1100011
//   U-type (LUI/AUIPC) : 0110111 / 0010111
//   J-type (JAL)       : 1101111
//////////////////////////////////////////////////////////////////////////////////

module imm_gen (
    input  [31:0] instr,
    output reg [31:0] imm
);

    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            // I-type: sign-extend instr[31:20]
            7'b0010011,   // I-type ALU (ADDI, ANDI, ORI, …)
            7'b0000011,   // Load
            7'b1100111:   // JALR
                imm = {{20{instr[31]}}, instr[31:20]};

            // S-type
            7'b0100011:
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type  (note the bit scrambling in the encoding)
            7'b1100011:
                imm = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};

            // U-type: upper 20 bits, zero-fill lower 12
            7'b0110111,   // LUI
            7'b0010111:   // AUIPC
                imm = {instr[31:12], 12'b0};

            // J-type (JAL)
            7'b1101111:
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                       instr[20], instr[30:21], 1'b0};

            default:
                imm = 32'b0;
        endcase
    end

endmodule
