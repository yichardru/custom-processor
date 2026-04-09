`timescale 1ns / 1ps

module mem_wb_reg (
    input         clk,
    input         reset,
    // Control signals in
    input         mem_reg_write,
    input  [1:0]  mem_mem_to_reg,
    // Data in
    input  [31:0] mem_alu_result,
    input  [31:0] mem_read_data,
    input  [31:0] mem_pc_plus4,
    input  [4:0]  mem_rd_addr,
    // Control signals out
    output reg        wb_reg_write,
    output reg [1:0]  wb_mem_to_reg,
    // Data out
    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_read_data,
    output reg [31:0] wb_pc_plus4,
    output reg [4:0]  wb_rd_addr
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wb_reg_write  <= 1'b0;
            wb_mem_to_reg <= 2'b00;
            wb_alu_result <= 32'b0;
            wb_read_data  <= 32'b0;
            wb_pc_plus4   <= 32'b0;
            wb_rd_addr    <= 5'b0;
        end else begin
            wb_reg_write  <= mem_reg_write;
            wb_mem_to_reg <= mem_mem_to_reg;
            wb_alu_result <= mem_alu_result;
            wb_read_data  <= mem_read_data;
            wb_pc_plus4   <= mem_pc_plus4;
            wb_rd_addr    <= mem_rd_addr;
        end
    end

endmodule
