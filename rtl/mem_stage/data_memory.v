`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: data_memory
// Description: Byte-addressable data memory (256 words = 1 KB).
//              Supports byte (LB/SB), halfword (LH/SH), and word (LW/SW)
//              accesses determined by funct3.
//
// Load funct3 encoding:
//   3'b000  LB  – sign-extend byte
//   3'b001  LH  – sign-extend halfword
//   3'b010  LW  – word
//   3'b100  LBU – zero-extend byte
//   3'b101  LHU – zero-extend halfword
//
// Store funct3 encoding:
//   3'b000  SB  – store byte
//   3'b001  SH  – store halfword
//   3'b010  SW  – store word
//
// Note: Only aligned accesses are supported (as stated in the README).
//////////////////////////////////////////////////////////////////////////////////

module data_memory (
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [31:0] addr,
    input  [31:0] write_data,
    input  [2:0]  funct3,
    output reg [31:0] read_data
);

    reg [31:0] memory [0:255]; // 256 × 32-bit words (1 KB)

    wire [7:0]  word_addr   = addr[9:2];   // word index
    wire [1:0]  byte_offset = addr[1:0];   // byte lane within the word

    // Synchronous writes
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB
                    case (byte_offset)
                        2'b00: memory[word_addr][ 7: 0] <= write_data[7:0];
                        2'b01: memory[word_addr][15: 8] <= write_data[7:0];
                        2'b10: memory[word_addr][23:16] <= write_data[7:0];
                        2'b11: memory[word_addr][31:24] <= write_data[7:0];
                    endcase
                end
                3'b001: begin // SH
                    case (byte_offset[1])
                        1'b0: memory[word_addr][15: 0] <= write_data[15:0];
                        1'b1: memory[word_addr][31:16] <= write_data[15:0];
                    endcase
                end
                3'b010: begin // SW
                    memory[word_addr] <= write_data;
                end
                default:; // unused
            endcase
        end
    end

    // Combinational reads
    wire [31:0] raw_word = memory[word_addr];

    always @(*) begin
        read_data = 32'b0;
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB
                    case (byte_offset)
                        2'b00: read_data = {{24{raw_word[ 7]}}, raw_word[ 7: 0]};
                        2'b01: read_data = {{24{raw_word[15]}}, raw_word[15: 8]};
                        2'b10: read_data = {{24{raw_word[23]}}, raw_word[23:16]};
                        2'b11: read_data = {{24{raw_word[31]}}, raw_word[31:24]};
                    endcase
                end
                3'b001: begin // LH
                    case (byte_offset[1])
                        1'b0: read_data = {{16{raw_word[15]}}, raw_word[15: 0]};
                        1'b1: read_data = {{16{raw_word[31]}}, raw_word[31:16]};
                    endcase
                end
                3'b010: read_data = raw_word; // LW
                3'b100: begin // LBU
                    case (byte_offset)
                        2'b00: read_data = {24'b0, raw_word[ 7: 0]};
                        2'b01: read_data = {24'b0, raw_word[15: 8]};
                        2'b10: read_data = {24'b0, raw_word[23:16]};
                        2'b11: read_data = {24'b0, raw_word[31:24]};
                    endcase
                end
                3'b101: begin // LHU
                    case (byte_offset[1])
                        1'b0: read_data = {16'b0, raw_word[15: 0]};
                        1'b1: read_data = {16'b0, raw_word[31:16]};
                    endcase
                end
                default: read_data = raw_word;
            endcase
        end
    end

endmodule
