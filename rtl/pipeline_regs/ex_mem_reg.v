`timescale 1ns / 1ps

module ex_mem_reg (
    input         clk,
    input         reset,
    // Control signals in
    input         ex_reg_write,
    input         ex_mem_read,
    input         ex_mem_write,
    input  [1:0]  ex_mem_to_reg,
    input  [2:0]  ex_funct3,
    // Data in
    input  [31:0] ex_alu_result,
    input  [31:0] ex_rs2_forwarded,
    input  [31:0] ex_pc_plus4,
    input  [4:0]  ex_rd_addr,
    // Control signals out
    output reg        mem_reg_write,
    output reg        mem_mem_read,
    output reg        mem_mem_write,
    output reg [1:0]  mem_mem_to_reg,
    output reg [2:0]  mem_funct3,
    // Data out
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rs2_data,
    output reg [31:0] mem_pc_plus4,
    output reg [4:0]  mem_rd_addr
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_reg_write  <= 1'b0;
            mem_mem_read   <= 1'b0;
            mem_mem_write  <= 1'b0;
            mem_mem_to_reg <= 2'b00;
            mem_funct3     <= 3'b0;
            mem_alu_result <= 32'b0;
            mem_rs2_data   <= 32'b0;
            mem_pc_plus4   <= 32'b0;
            mem_rd_addr    <= 5'b0;
        end else begin
            mem_reg_write  <= ex_reg_write;
            mem_mem_read   <= ex_mem_read;
            mem_mem_write  <= ex_mem_write;
            mem_mem_to_reg <= ex_mem_to_reg;
            mem_funct3     <= ex_funct3;
            mem_alu_result <= ex_alu_result;
            mem_rs2_data   <= ex_rs2_forwarded;
            mem_pc_plus4   <= ex_pc_plus4;
            mem_rd_addr    <= ex_rd_addr;
        end
    end

endmodule
