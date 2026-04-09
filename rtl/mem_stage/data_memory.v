`timescale 1ns / 1ps

module data_memory (
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [2:0]  funct3,
    input  [31:0] addr,
    input  [31:0] write_data,
    output reg [31:0] read_data
);

    reg [7:0] memory [0:1023]; // 1KB byte-addressable

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 8'b0;
    end

    // Combinational read with width/sign handling
    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000:  read_data = {{24{memory[addr[9:0]][7]}}, memory[addr[9:0]]};                                          // LB
                3'b001:  read_data = {{16{memory[addr[9:0]+1][7]}}, memory[addr[9:0]+1], memory[addr[9:0]]};                   // LH
                3'b010:  read_data = {memory[addr[9:0]+3], memory[addr[9:0]+2], memory[addr[9:0]+1], memory[addr[9:0]]};       // LW
                3'b100:  read_data = {24'b0, memory[addr[9:0]]};                                                               // LBU
                3'b101:  read_data = {16'b0, memory[addr[9:0]+1], memory[addr[9:0]]};                                          // LHU
                default: read_data = 32'b0;
            endcase
        end else begin
            read_data = 32'b0;
        end
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: // SB
                    memory[addr[9:0]] <= write_data[7:0];
                3'b001: begin // SH
                    memory[addr[9:0]]   <= write_data[7:0];
                    memory[addr[9:0]+1] <= write_data[15:8];
                end
                3'b010: begin // SW
                    memory[addr[9:0]]   <= write_data[7:0];
                    memory[addr[9:0]+1] <= write_data[15:8];
                    memory[addr[9:0]+2] <= write_data[23:16];
                    memory[addr[9:0]+3] <= write_data[31:24];
                end
            endcase
        end
    end

endmodule
