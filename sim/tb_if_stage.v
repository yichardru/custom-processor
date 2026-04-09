`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_if_stage
// Description: Verifies:
//   1. Sequential instruction fetch (PC advances by 4 each cycle).
//   2. Stall: PC holds when pc_write_en=0.
//   3. Branch: PC jumps to branch_target when branch_taken=1.
//////////////////////////////////////////////////////////////////////////////////

module tb_if_stage;

    parameter CLK_HALF = 5;

    reg        clk, reset, pc_write_en, branch_taken;
    reg [31:0] branch_target;
    wire [31:0] instr_out, pc_out;

    integer pass_count = 0;
    integer fail_count = 0;

    if_stage dut (
        .clk          (clk),
        .reset        (reset),
        .pc_write_en  (pc_write_en),
        .branch_target(branch_target),
        .branch_taken (branch_taken),
        .instr_out    (instr_out),
        .pc_out       (pc_out)
    );

    always #CLK_HALF clk = ~clk;

    task check32;
        input [31:0] got;
        input [31:0] exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got 0x%08h, expected 0x%08h",
                         $time, name, got, exp);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_if_stage ===");
        clk = 0; reset = 1; pc_write_en = 1;
        branch_taken = 0; branch_target = 32'b0;
        @(posedge clk); #1;

        reset = 0;

        // Cycle 0: PC = 0x00 (just released reset)
        check32(pc_out, 32'h00000000, "PC after reset");

        @(posedge clk); #1;
        // Cycle 1: PC = 0x04
        check32(pc_out, 32'h00000004, "PC cycle 1");

        @(posedge clk); #1;
        // Cycle 2: PC = 0x08
        check32(pc_out, 32'h00000008, "PC cycle 2");

        // Stall: hold PC at 0x08
        pc_write_en = 0;
        @(posedge clk); #1;
        check32(pc_out, 32'h00000008, "PC stall hold");

        @(posedge clk); #1;
        check32(pc_out, 32'h00000008, "PC stall 2nd cycle");

        // Resume
        pc_write_en = 1;
        @(posedge clk); #1;
        check32(pc_out, 32'h0000000C, "PC resume after stall");

        // Branch taken: jump to 0x20
        branch_taken  = 1;
        branch_target = 32'h00000020;
        @(posedge clk); #1;
        branch_taken = 0;
        check32(pc_out, 32'h00000020, "PC after branch");

        // Continues from branch target
        @(posedge clk); #1;
        check32(pc_out, 32'h00000024, "PC branch+4");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
