`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_processor_top
// Description: Integration test for the complete 5-stage pipelined processor.
//
// Test program (program.mem):
//   PC=0x00  ADDI x1, x0,  5   → x1 = 5
//   PC=0x04  ADDI x2, x0, 10   → x2 = 10
//   PC=0x08  ADD  x3, x1,  x2  → x3 = 15   (exercises EX/MEM→EX forwarding)
//   PC=0x0C  SW   x3, 0(x0)    → mem[0] = 15
//   PC=0x10  LW   x4, 0(x0)    → x4 = 15   (exercises load-use stall)
//   PC=0x14  ADD  x5, x4,  x1  → x5 = 20   (exercises MEM/WB→EX forwarding)
//   PC=0x18  ADDI x6, x0, 15   → x6 = 15
//   PC=0x1C  BEQ  x3, x6, +8  → branch to 0x24 (taken; exercises branch flush)
//   PC=0x20  ADDI x8, x0,  1   → FLUSHED – x8 must remain 0
//   PC=0x24  ADDI x9, x0, 42   → x9 = 42  (branch target)
//   PC=0x28  NOP (infinite)
//////////////////////////////////////////////////////////////////////////////////

module tb_processor_top;

    parameter CLK_HALF = 5;

    reg clk, reset;

    integer pass_count = 0;
    integer fail_count = 0;

    processor_top dut (
        .clk   (clk),
        .reset (reset)
    );

    always #CLK_HALF clk = ~clk;

    // Hierarchical access to the internal register file
    // dut.id_inst.rf.regs[n]
    task check_reg;
        input integer  regnum;
        input [31:0]   expected;
        input [127:0]  name;
        reg   [31:0]   got;
        begin
            got = dut.id_inst.rf.regs[regnum];
            if (got !== expected) begin
                $display("FAIL %s (x%0d): got 0x%08h, expected 0x%08h",
                         name, regnum, got, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS %s (x%0d) = 0x%08h", name, regnum, got);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_processor_top ===");
        clk = 0; reset = 1;
        repeat (3) @(posedge clk);
        reset = 0;

        // Run for enough cycles to complete the program.
        // The program has 10 instructions + 1 load-use stall cycle + 2 branch
        // flush cycles ≈ 15 useful cycles, plus the 5-stage fill latency.
        // 60 cycles is more than sufficient.
        repeat (60) @(posedge clk);
        #1; // settle combinational logic

        $display("--- Register file state ---");
        check_reg(1,  32'd5,   "ADDI x1");
        check_reg(2,  32'd10,  "ADDI x2");
        check_reg(3,  32'd15,  "ADD  x3");
        check_reg(4,  32'd15,  "LW   x4");
        check_reg(5,  32'd20,  "ADD  x5 (load-use fwd)");
        check_reg(6,  32'd15,  "ADDI x6");
        check_reg(8,  32'd0,   "x8 stays 0 (branch flushed)");
        check_reg(9,  32'd42,  "ADDI x9 (branch target)");

        $display("--- Memory state ---");
        if (dut.mem_inst.dmem.memory[0] === 32'd15)
            $display("PASS mem[0] = 15 (SW/LW verify)");
        else begin
            $display("FAIL mem[0]: got %0d, expected 15",
                     dut.mem_inst.dmem.memory[0]);
            fail_count = fail_count + 1;
        end

        $display("---");
        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("PASS – all integration checks passed");
        else
            $display("FAIL – %0d check(s) failed", fail_count);

        $finish;
    end

    // Optional: dump waveform for debugging
    // initial begin
    //     $dumpfile("processor_top.vcd");
    //     $dumpvars(0, tb_processor_top);
    // end

endmodule
