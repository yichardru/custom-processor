`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: control_unit
// Description: Combinational control signal decoder for RV32I opcodes.
//              Outputs drive both the datapath and the ID/EX pipeline register.
//
// mem_to_reg encoding:
//   2'b00 = ALU result
//   2'b01 = data memory read
//   2'b10 = PC+4 (JAL / JALR return address)
//
// alu_op encoding:
//   2'b00 = force ADD  (loads, stores, AUIPC, JAL, JALR)
//   2'b01 = force SUB  (branch comparison)
//   2'b10 = use funct3/funct7 (R-type, I-type ALU)
//   2'b11 = pass B     (LUI – result = immediate)
//////////////////////////////////////////////////////////////////////////////////

module control_unit (
    input  [6:0] opcode,
    output reg       reg_write,
    output reg       alu_src_b,   // 0 = rs2, 1 = immediate
    output reg       alu_src_a,   // 0 = rs1, 1 = PC
    output reg       mem_read,
    output reg       mem_write,
    output reg [1:0] mem_to_reg,
    output reg       branch,
    output reg       jump,
    output reg       jalr,
    output reg [1:0] alu_op
);

    // RV32I opcode map
    localparam OP_R      = 7'b0110011;
    localparam OP_I_ALU  = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;

    always @(*) begin
        // Safe defaults – behave as NOP
        reg_write  = 1'b0;
        alu_src_b  = 1'b0;
        alu_src_a  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                alu_op    = 2'b10;
            end

            OP_I_ALU: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = 2'b10;
            end

            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 2'b01;
                alu_op     = 2'b00;
            end

            OP_STORE: begin
                alu_src_b = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00;
            end

            OP_BRANCH: begin
                branch = 1'b1;
                alu_op = 2'b01;  // SUB to obtain comparison flags
            end

            OP_LUI: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = 2'b11;  // pass B (imm) directly
            end

            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src_a = 1'b1;  // A = PC
                alu_src_b = 1'b1;
                alu_op    = 2'b00;  // ADD: PC + imm
            end

            OP_JAL: begin
                reg_write  = 1'b1;
                alu_src_a  = 1'b1;  // A = PC for target computation
                alu_src_b  = 1'b1;
                jump       = 1'b1;
                mem_to_reg = 2'b10; // rd = PC+4
                alu_op     = 2'b00; // ADD: PC + imm  →  jump target
            end

            OP_JALR: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                jump       = 1'b1;
                jalr       = 1'b1;
                mem_to_reg = 2'b10; // rd = PC+4
                alu_op     = 2'b00; // ADD: rs1 + imm  →  jump target (bit 0 cleared in EX)
            end

            default: begin
                // unknown / fence / ecall: treat as NOP
            end
        endcase
    end

endmodule
