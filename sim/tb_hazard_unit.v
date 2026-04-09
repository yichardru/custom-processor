`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_hazard_unit
// Description: Tests:
//   1. No hazard – all enable/flush outputs in normal state.
//   2. Load-use stall – PC and IF/ID stalled, ID/EX flushed.
//   3. EX/MEM forwarding (forwardA/B = 10).
//   4. MEM/WB forwarding (forwardA/B = 01).
//   5. EX hazard takes priority over MEM hazard.
//   6. Branch taken – IF/ID and ID/EX flushed, PC allowed to redirect.
//   7. Branch + load-use simultaneously – branch flush takes priority.
//////////////////////////////////////////////////////////////////////////////////

module tb_hazard_unit;

    reg        id_ex_mem_read;
    reg [4:0]  id_ex_rd;
    reg [4:0]  if_id_rs1, if_id_rs2;
    reg [4:0]  id_ex_rs1, id_ex_rs2;
    reg        ex_mem_reg_write;
    reg [4:0]  ex_mem_rd;
    reg        mem_wb_reg_write;
    reg [4:0]  mem_wb_rd;
    reg        branch_taken;

    wire        pc_write_en, if_id_write_en;
    wire        id_ex_flush, if_id_flush;
    wire [1:0]  forwardA, forwardB;

    integer pass_count = 0;
    integer fail_count = 0;

    hazard_unit dut (
        .id_ex_mem_read  (id_ex_mem_read),
        .id_ex_rd        (id_ex_rd),
        .if_id_rs1       (if_id_rs1),
        .if_id_rs2       (if_id_rs2),
        .id_ex_rs1       (id_ex_rs1),
        .id_ex_rs2       (id_ex_rs2),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_rd       (ex_mem_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_rd       (mem_wb_rd),
        .branch_taken    (branch_taken),
        .pc_write_en     (pc_write_en),
        .if_id_write_en  (if_id_write_en),
        .id_ex_flush     (id_ex_flush),
        .if_id_flush     (if_id_flush),
        .forwardA        (forwardA),
        .forwardB        (forwardB)
    );

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

    task check2;
        input [1:0] got;
        input [1:0] exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got %02b, exp %02b",
                         $time, name, got, exp);
                fail_count = fail_count + 1;
            end else
                pass_count = pass_count + 1;
        end
    endtask

    // Reset all inputs to benign values
    task set_defaults;
        begin
            id_ex_mem_read=0; id_ex_rd=5'd0;
            if_id_rs1=5'd0; if_id_rs2=5'd0;
            id_ex_rs1=5'd0; id_ex_rs2=5'd0;
            ex_mem_reg_write=0; ex_mem_rd=5'd0;
            mem_wb_reg_write=0; mem_wb_rd=5'd0;
            branch_taken=0;
        end
    endtask

    initial begin
        $display("=== tb_hazard_unit ===");
        set_defaults; #1;

        // ---- 1. No hazard ----
        check1(pc_write_en,   1, "no-hazard pc_write_en");
        check1(if_id_write_en,1, "no-hazard if_id_write_en");
        check1(id_ex_flush,   0, "no-hazard id_ex_flush");
        check1(if_id_flush,   0, "no-hazard if_id_flush");
        check2(forwardA, 2'b00,  "no-hazard forwardA");
        check2(forwardB, 2'b00,  "no-hazard forwardB");

        // ---- 2. Load-use stall: LW x1 in EX, next instr reads x1 ----
        id_ex_mem_read=1; id_ex_rd=5'd1;
        if_id_rs1=5'd1; if_id_rs2=5'd2; #1;
        check1(pc_write_en,   0, "load-use pc_write_en=0");
        check1(if_id_write_en,0, "load-use if_id_write_en=0");
        check1(id_ex_flush,   1, "load-use id_ex_flush=1");
        check1(if_id_flush,   0, "load-use if_id_flush=0");

        // ---- 2b. Load-use stall via rs2 match ----
        if_id_rs1=5'd3; if_id_rs2=5'd1; #1;
        check1(id_ex_flush, 1, "load-use rs2 match");

        // ---- 2c. No stall when rd = x0 ----
        id_ex_rd=5'd0; if_id_rs1=5'd0; if_id_rs2=5'd0; #1;
        check1(id_ex_flush, 0, "load-use x0 no stall");
        set_defaults; #1;

        // ---- 3. EX/MEM forwarding: ex_mem_rd matches id_ex_rs1 ----
        ex_mem_reg_write=1; ex_mem_rd=5'd3;
        id_ex_rs1=5'd3; id_ex_rs2=5'd5; #1;
        check2(forwardA, 2'b10, "EX/MEM forwardA");
        check2(forwardB, 2'b00, "EX/MEM no forwardB");

        // EX/MEM also matches rs2
        id_ex_rs2=5'd3; #1;
        check2(forwardB, 2'b10, "EX/MEM forwardB");
        set_defaults; #1;

        // ---- 4. MEM/WB forwarding ----
        mem_wb_reg_write=1; mem_wb_rd=5'd7;
        id_ex_rs1=5'd7; id_ex_rs2=5'd7; #1;
        check2(forwardA, 2'b01, "MEM/WB forwardA");
        check2(forwardB, 2'b01, "MEM/WB forwardB");
        set_defaults; #1;

        // ---- 5. EX hazard overrides MEM hazard for same rd ----
        ex_mem_reg_write=1; ex_mem_rd=5'd4;
        mem_wb_reg_write=1; mem_wb_rd=5'd4;
        id_ex_rs1=5'd4; id_ex_rs2=5'd4; #1;
        check2(forwardA, 2'b10, "EX overrides MEM forwardA");
        check2(forwardB, 2'b10, "EX overrides MEM forwardB");
        set_defaults; #1;

        // ---- 6. Branch taken: flush IF/ID and ID/EX, keep pc_write_en ----
        branch_taken=1; #1;
        check1(pc_write_en,   1, "branch pc_write_en=1");
        check1(if_id_flush,   1, "branch if_id_flush=1");
        check1(id_ex_flush,   1, "branch id_ex_flush=1");
        check1(if_id_write_en,1, "branch if_id_write_en=1");
        set_defaults; #1;

        // ---- 7. Branch + load-use: branch takes priority ----
        branch_taken=1;
        id_ex_mem_read=1; id_ex_rd=5'd2;
        if_id_rs1=5'd2; #1;
        check1(pc_write_en,   1, "branch+load: pc_write_en=1");
        check1(if_id_flush,   1, "branch+load: if_id_flush=1");
        check1(id_ex_flush,   1, "branch+load: id_ex_flush=1");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
