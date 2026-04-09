`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_pipeline_regs
// Description: Tests all four pipeline registers:
//   if_id_reg  – flush, stall (write_en=0), and normal advance.
//   id_ex_reg  – flush (NOP bubble) and normal advance.
//   ex_mem_reg – reset clear and normal advance.
//   mem_wb_reg – reset clear and normal advance.
//////////////////////////////////////////////////////////////////////////////////

module tb_pipeline_regs;

    parameter CLK_HALF = 5;
    reg clk, reset;

    integer pass_count = 0;
    integer fail_count = 0;

    always #CLK_HALF clk = ~clk;

    task check32;
        input [31:0] got;
        input [31:0] exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got 0x%08h, exp 0x%08h",
                         $time, name, got, exp);
                fail_count = fail_count + 1;
            end else
                pass_count = pass_count + 1;
        end
    endtask

    task check1;
        input got;
        input exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got %b, exp %b",
                         $time, name, got, exp);
                fail_count = fail_count + 1;
            end else
                pass_count = pass_count + 1;
        end
    endtask

    // ================================================================== //
    //  IF/ID register
    // ================================================================== //
    reg        ifid_flush, ifid_we;
    reg [31:0] ifid_instr_in, ifid_pc_in;
    wire [31:0] ifid_instr_out, ifid_pc_out;

    if_id_reg u_if_id (
        .clk      (clk), .reset(reset),
        .flush    (ifid_flush), .write_en(ifid_we),
        .instr_in (ifid_instr_in), .pc_in(ifid_pc_in),
        .instr_out(ifid_instr_out), .pc_out(ifid_pc_out)
    );

    // ================================================================== //
    //  ID/EX register (only a subset of ports tested for clarity)
    // ================================================================== //
    reg        idex_flush;
    reg [31:0] idex_rs1_in, idex_imm_in, idex_pc_in;
    reg        idex_reg_write_in, idex_mem_read_in;

    wire [31:0] idex_rs1_out, idex_imm_out, idex_pc_out;
    wire        idex_reg_write_out, idex_mem_read_out;

    id_ex_reg u_id_ex (
        .clk(clk), .reset(reset), .flush(idex_flush),
        .rs1_data_in(idex_rs1_in), .rs2_data_in(32'b0),
        .imm_in(idex_imm_in), .pc_in(idex_pc_in), .pc_plus4_in(32'b0),
        .rs1_addr_in(5'b0), .rs2_addr_in(5'b0), .rd_addr_in(5'b0),
        .funct3_in(3'b0), .funct7b5_in(1'b0),
        .reg_write_in(idex_reg_write_in), .alu_src_b_in(1'b0),
        .alu_src_a_in(1'b0), .mem_read_in(idex_mem_read_in),
        .mem_write_in(1'b0), .mem_to_reg_in(2'b0),
        .branch_in(1'b0), .jump_in(1'b0), .jalr_in(1'b0),
        .alu_op_in(2'b0),
        .rs1_data_out(idex_rs1_out), .rs2_data_out(),
        .imm_out(idex_imm_out), .pc_out(idex_pc_out), .pc_plus4_out(),
        .rs1_addr_out(), .rs2_addr_out(), .rd_addr_out(),
        .funct3_out(), .funct7b5_out(),
        .reg_write_out(idex_reg_write_out), .alu_src_b_out(),
        .alu_src_a_out(), .mem_read_out(idex_mem_read_out),
        .mem_write_out(), .mem_to_reg_out(),
        .branch_out(), .jump_out(), .jalr_out(), .alu_op_out()
    );

    // ================================================================== //
    //  EX/MEM register
    // ================================================================== //
    reg [31:0] exmem_alu_in, exmem_pc4_in;
    reg        exmem_rw_in, exmem_mr_in;
    wire [31:0] exmem_alu_out, exmem_pc4_out;
    wire        exmem_rw_out, exmem_mr_out;

    ex_mem_reg u_ex_mem (
        .clk(clk), .reset(reset),
        .alu_result_in(exmem_alu_in), .rs2_data_in(32'b0),
        .rd_addr_in(5'b0), .pc_plus4_in(exmem_pc4_in), .funct3_in(3'b0),
        .reg_write_in(exmem_rw_in), .mem_read_in(exmem_mr_in),
        .mem_write_in(1'b0), .mem_to_reg_in(2'b0),
        .alu_result_out(exmem_alu_out), .rs2_data_out(),
        .rd_addr_out(), .pc_plus4_out(exmem_pc4_out), .funct3_out(),
        .reg_write_out(exmem_rw_out), .mem_read_out(exmem_mr_out),
        .mem_write_out(), .mem_to_reg_out()
    );

    // ================================================================== //
    //  MEM/WB register
    // ================================================================== //
    reg [31:0] memwb_alu_in, memwb_mem_in;
    reg        memwb_rw_in;
    wire [31:0] memwb_alu_out, memwb_mem_out;
    wire        memwb_rw_out;

    mem_wb_reg u_mem_wb (
        .clk(clk), .reset(reset),
        .alu_result_in(memwb_alu_in), .mem_data_in(memwb_mem_in),
        .rd_addr_in(5'b0), .pc_plus4_in(32'b0),
        .reg_write_in(memwb_rw_in), .mem_to_reg_in(2'b0),
        .alu_result_out(memwb_alu_out), .mem_data_out(memwb_mem_out),
        .rd_addr_out(), .pc_plus4_out(),
        .reg_write_out(memwb_rw_out), .mem_to_reg_out()
    );

    initial begin
        $display("=== tb_pipeline_regs ===");
        clk=0; reset=1;
        ifid_flush=0; ifid_we=1;
        ifid_instr_in=0; ifid_pc_in=0;
        idex_flush=0;
        idex_rs1_in=0; idex_imm_in=0; idex_pc_in=0;
        idex_reg_write_in=0; idex_mem_read_in=0;
        exmem_alu_in=0; exmem_pc4_in=0;
        exmem_rw_in=0; exmem_mr_in=0;
        memwb_alu_in=0; memwb_mem_in=0; memwb_rw_in=0;
        @(posedge clk); #1;
        reset=0;

        // ---- IF/ID normal advance ----
        ifid_instr_in=32'hABCD1234; ifid_pc_in=32'h100;
        @(posedge clk); #1;
        check32(ifid_instr_out, 32'hABCD1234, "IF/ID instr advance");
        check32(ifid_pc_out,    32'h100,      "IF/ID pc advance");

        // ---- IF/ID stall (write_en=0) ----
        ifid_we=0; ifid_instr_in=32'hDEAD; ifid_pc_in=32'h200;
        @(posedge clk); #1;
        check32(ifid_instr_out, 32'hABCD1234, "IF/ID stall holds value");
        ifid_we=1;

        // ---- IF/ID flush → NOP ----
        ifid_flush=1; ifid_instr_in=32'hFFFFFFFF;
        @(posedge clk); #1;
        ifid_flush=0;
        check32(ifid_instr_out, 32'h00000013, "IF/ID flush = NOP");

        // ---- ID/EX normal advance ----
        idex_rs1_in=32'hCAFE; idex_imm_in=32'hBEEF;
        idex_pc_in=32'h40; idex_reg_write_in=1; idex_mem_read_in=1;
        @(posedge clk); #1;
        check32(idex_rs1_out,       32'hCAFE, "ID/EX rs1 advance");
        check32(idex_imm_out,       32'hBEEF, "ID/EX imm advance");
        check1(idex_reg_write_out,  1,        "ID/EX reg_write advance");
        check1(idex_mem_read_out,   1,        "ID/EX mem_read advance");

        // ---- ID/EX flush → all zeros ----
        idex_flush=1;
        @(posedge clk); #1;
        idex_flush=0;
        check32(idex_rs1_out,      32'b0, "ID/EX flush rs1=0");
        check1(idex_reg_write_out, 0,     "ID/EX flush reg_write=0");
        check1(idex_mem_read_out,  0,     "ID/EX flush mem_read=0");

        // ---- EX/MEM normal advance ----
        exmem_alu_in=32'h12345678; exmem_pc4_in=32'h104;
        exmem_rw_in=1; exmem_mr_in=1;
        @(posedge clk); #1;
        check32(exmem_alu_out, 32'h12345678, "EX/MEM alu advance");
        check32(exmem_pc4_out, 32'h104,      "EX/MEM pc4 advance");
        check1(exmem_rw_out,  1,             "EX/MEM rw advance");

        // ---- EX/MEM reset ----
        reset=1; @(posedge clk); #1; reset=0;
        check32(exmem_alu_out, 32'b0, "EX/MEM reset");

        // ---- MEM/WB normal advance ----
        memwb_alu_in=32'hFACE; memwb_mem_in=32'hD00D; memwb_rw_in=1;
        @(posedge clk); #1;
        check32(memwb_alu_out, 32'hFACE, "MEM/WB alu advance");
        check32(memwb_mem_out, 32'hD00D, "MEM/WB mem advance");
        check1(memwb_rw_out,  1,         "MEM/WB rw advance");

        // ---- MEM/WB reset ----
        reset=1; @(posedge clk); #1; reset=0;
        check32(memwb_alu_out, 32'b0, "MEM/WB reset");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
