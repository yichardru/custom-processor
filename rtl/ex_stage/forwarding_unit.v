`timescale 1ns / 1ps

module forwarding_unit (
    input  [4:0] id_ex_rs1,
    input  [4:0] id_ex_rs2,
    input  [4:0] ex_mem_rd,
    input        ex_mem_reg_write,
    input  [4:0] mem_wb_rd,
    input        mem_wb_reg_write,
    output reg [1:0] forward_a,   // 00: no fwd, 01: MEM/WB, 10: EX/MEM
    output reg [1:0] forward_b
);

    // Forward A (rs1 source)
    always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1))
            forward_a = 2'b10;  // EX hazard (priority: more recent)
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1))
            forward_a = 2'b01;  // MEM hazard
        else
            forward_a = 2'b00;  // no forwarding
    end

    // Forward B (rs2 source)
    always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2))
            forward_b = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end

endmodule
