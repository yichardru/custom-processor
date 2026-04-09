`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_mem_stage
// Description: Exercises mem_stage (which wraps data_memory).
//              Verifies word, halfword, and byte load/store plus pass-through.
//////////////////////////////////////////////////////////////////////////////////

module tb_mem_stage;

    parameter CLK_HALF = 5;

    reg         clk;
    reg  [31:0] alu_result, rs2_data, pc_plus4;
    reg  [4:0]  rd_addr;
    reg  [2:0]  funct3;
    reg         mem_read, mem_write;

    wire [31:0] alu_result_out, mem_data, pc_plus4_out;
    wire [4:0]  rd_addr_out;

    integer pass_count = 0;
    integer fail_count = 0;

    mem_stage dut (
        .clk           (clk),
        .alu_result    (alu_result),
        .rs2_data      (rs2_data),
        .rd_addr       (rd_addr),
        .pc_plus4      (pc_plus4),
        .funct3        (funct3),
        .mem_read      (mem_read),
        .mem_write     (mem_write),
        .alu_result_out(alu_result_out),
        .mem_data      (mem_data),
        .rd_addr_out   (rd_addr_out),
        .pc_plus4_out  (pc_plus4_out)
    );

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

    task check5;
        input [4:0] got;
        input [4:0] exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got %05b, exp %05b",
                         $time, name, got, exp);
                fail_count = fail_count + 1;
            end else
                pass_count = pass_count + 1;
        end
    endtask

    initial begin
        $display("=== tb_mem_stage ===");
        clk=0; mem_read=0; mem_write=0;
        alu_result=0; rs2_data=0; rd_addr=0;
        pc_plus4=0; funct3=3'b010;
        #1;

        // ---- SW then LW ----
        alu_result=32'h10; rs2_data=32'hCAFE_BABE;
        mem_write=1; mem_read=0; funct3=3'b010;
        @(posedge clk); #1;
        mem_write=0; mem_read=1; #1;
        check32(mem_data, 32'hCAFEBABE, "LW after SW");

        // ---- Pass-through: alu_result, rd_addr, pc_plus4 ----
        alu_result=32'hDEAD; rd_addr=5'd7; pc_plus4=32'h104;
        mem_read=0; #1;
        check32(alu_result_out, 32'hDEAD, "alu_result pass-through");
        check5(rd_addr_out, 5'd7,         "rd_addr pass-through");
        check32(pc_plus4_out, 32'h104,    "pc_plus4 pass-through");

        // ---- SB / LB ----
        alu_result=32'h20; rs2_data=32'h000000AB;
        mem_write=1; funct3=3'b000;
        @(posedge clk); #1;
        mem_write=0; mem_read=1; #1;
        check32(mem_data, 32'hFFFFFFAB, "LB sign-extend 0xAB");

        // ---- LBU ----
        funct3=3'b100; #1;
        check32(mem_data, 32'h000000AB, "LBU zero-extend 0xAB");

        // ---- SH / LH ----
        alu_result=32'h30; rs2_data=32'h00008FFF;
        mem_write=1; mem_read=0; funct3=3'b001;
        @(posedge clk); #1;
        mem_write=0; mem_read=1; #1;
        check32(mem_data, 32'hFFFF8FFF, "LH sign-extend 0x8FFF");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
