`timescale 1ns / 1ps

module alu_control (
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input        funct7_bit5,
    output reg [3:0] alu_ctrl
);

    // ALU control encoding:
    // 0000: ADD    0001: SUB     0010: SLL    0011: SLT
    // 0100: SLTU   0101: XOR     0110: SRL    0111: SRA
    // 1000: OR     1001: AND

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000; // ADD (loads, stores, LUI, AUIPC, JAL, JALR)

            2'b01: alu_ctrl = 4'b0001; // SUB (branches - unused by ALU, branch unit handles comparison)

            2'b10: begin // R-type
                case (funct3)
                    3'b000: alu_ctrl = funct7_bit5 ? 4'b0001 : 4'b0000; // SUB / ADD
                    3'b001: alu_ctrl = 4'b0010; // SLL
                    3'b010: alu_ctrl = 4'b0011; // SLT
                    3'b011: alu_ctrl = 4'b0100; // SLTU
                    3'b100: alu_ctrl = 4'b0101; // XOR
                    3'b101: alu_ctrl = funct7_bit5 ? 4'b0111 : 4'b0110; // SRA / SRL
                    3'b110: alu_ctrl = 4'b1000; // OR
                    3'b111: alu_ctrl = 4'b1001; // AND
                endcase
            end

            2'b11: begin // I-type ALU
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADDI
                    3'b001: alu_ctrl = 4'b0010; // SLLI
                    3'b010: alu_ctrl = 4'b0011; // SLTI
                    3'b011: alu_ctrl = 4'b0100; // SLTIU
                    3'b100: alu_ctrl = 4'b0101; // XORI
                    3'b101: alu_ctrl = funct7_bit5 ? 4'b0111 : 4'b0110; // SRAI / SRLI
                    3'b110: alu_ctrl = 4'b1000; // ORI
                    3'b111: alu_ctrl = 4'b1001; // ANDI
                endcase
            end
        endcase
    end

endmodule
