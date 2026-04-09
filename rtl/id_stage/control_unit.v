`timescale 1ns / 1ps

module control_unit (
    input  [6:0] opcode,
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       alu_src,       // 0: rs2, 1: immediate
    output reg [1:0] alu_op,
    output reg       branch,
    output reg       jal,
    output reg       jalr,
    output reg [1:0] mem_to_reg,    // 00: ALU, 01: mem, 10: PC+4
    output reg [1:0] alu_src_a      // 00: rs1, 01: PC, 10: zero
);

    always @(*) begin
        // Defaults (NOP-safe)
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        alu_src   = 1'b0;
        alu_op    = 2'b00;
        branch    = 1'b0;
        jal       = 1'b0;
        jalr      = 1'b0;
        mem_to_reg = 2'b00;
        alu_src_a  = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_op    = 2'b10;
            end

            7'b0010011: begin // I-type ALU
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end

            7'b0000011: begin // Load
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 2'b01;
            end

            7'b0100011: begin // Store
                mem_write = 1'b1;
                alu_src   = 1'b1;
            end

            7'b1100011: begin // Branch
                branch = 1'b1;
                alu_op = 2'b01;
            end

            7'b1101111: begin // JAL
                reg_write  = 1'b1;
                jal        = 1'b1;
                mem_to_reg = 2'b10;
            end

            7'b1100111: begin // JALR
                reg_write  = 1'b1;
                jalr       = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 2'b10;
            end

            7'b0110111: begin // LUI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_src_a = 2'b10; // zero
            end

            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_src_a = 2'b01; // PC
            end

            default: ; // NOP / unknown
        endcase
    end

endmodule
