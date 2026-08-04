`timescale 1ns / 1ps

module processor_tb;

    // =========================================================================
    // Clock and Reset
    // =========================================================================
    reg clk;
    reg reset;

    // 10ns period clock (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // =========================================================================
    // DUT
    // =========================================================================
    processor_top dut (
        .clk(clk),
        .reset(reset)
    );

    // =========================================================================
    // Convenient hierarchical references
    // =========================================================================

    // Register file
    wire [31:0] x0  = dut.id_inst.rf.regs[0];
    wire [31:0] x1  = dut.id_inst.rf.regs[1];
    wire [31:0] x2  = dut.id_inst.rf.regs[2];
    wire [31:0] x3  = dut.id_inst.rf.regs[3];
    wire [31:0] x4  = dut.id_inst.rf.regs[4];
    wire [31:0] x5  = dut.id_inst.rf.regs[5];
    wire [31:0] x6  = dut.id_inst.rf.regs[6];
    wire [31:0] x7  = dut.id_inst.rf.regs[7];
    wire [31:0] x8  = dut.id_inst.rf.regs[8];
    wire [31:0] x9  = dut.id_inst.rf.regs[9];
    wire [31:0] x10 = dut.id_inst.rf.regs[10];
    wire [31:0] x11 = dut.id_inst.rf.regs[11];
    wire [31:0] x12 = dut.id_inst.rf.regs[12];
    wire [31:0] x13 = dut.id_inst.rf.regs[13];
    wire [31:0] x14 = dut.id_inst.rf.regs[14];
    wire [31:0] x15 = dut.id_inst.rf.regs[15];

    // PC
    wire [31:0] pc_val = dut.if_inst.pc_inst.pc_reg;

    // Pipeline register snapshots
    wire [31:0] ifid_instr = dut.if_id.id_instr;
    wire [31:0] ifid_pc    = dut.if_id.id_pc;

    wire [4:0]  idex_rd    = dut.id_ex.ex_rd_addr;
    wire [31:0] idex_rs1   = dut.id_ex.ex_rs1_data;
    wire [31:0] idex_rs2   = dut.id_ex.ex_rs2_data;
    wire [31:0] idex_imm   = dut.id_ex.ex_imm;
    wire [31:0] idex_pc    = dut.id_ex.ex_pc;

    wire [31:0] exmem_alu  = dut.ex_mem.mem_alu_result;
    wire [4:0]  exmem_rd   = dut.ex_mem.mem_rd_addr;

    wire [31:0] memwb_alu  = dut.mem_wb.wb_alu_result;
    wire [4:0]  memwb_rd   = dut.mem_wb.wb_rd_addr;

    // Forwarding / hazard
    wire [1:0] fwd_a = dut.fwd_unit.forward_a;
    wire [1:0] fwd_b = dut.fwd_unit.forward_b;
    wire       stall = ~dut.haz_unit.pc_write_en;
    wire       flush = dut.haz_unit.if_id_flush;

    // Branch
    wire branch_taken  = dut.branch_taken;
    wire [31:0] branch_target = dut.branch_target;

    // =========================================================================
    // Test sequence
    // =========================================================================
    integer cycle;
    integer pass_count;
    integer fail_count;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [8*40-1:0] msg;
        begin
            if (actual === expected) begin
                $display("  [PASS] %0s = 0x%08h", msg, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %0s = 0x%08h (expected 0x%08h)", msg, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // Optional VCD dump
        $dumpfile("processor_tb.vcd");
        $dumpvars(0, processor_tb);

        pass_count = 0;
        fail_count = 0;
        cycle = 0;

        // =====================================================================
        // Reset
        // =====================================================================
        $display("\n===== RISC-V Pipelined Processor Testbench =====\n");
        reset = 1;
        #20;
        reset = 0;

        // =====================================================================
        // Run for enough cycles for all instructions to complete
        // The test program in program.mem should be loaded at reset.
        //
        // Test program (see sim/program.mem):
        //   0x00: addi x5, x0, 5       # x5 = 5
        //   0x04: addi x6, x0, 10      # x6 = 10
        //   0x08: add  x7, x5, x6      # x7 = 15        (EX-EX fwd from x6, MEM-EX fwd from x5)
        //   0x0C: sub  x8, x7, x5      # x8 = 10        (EX-EX fwd from x7)
        //   0x10: sw   x7, 0(x0)       # mem[0] = 15
        //   0x14: lw   x9, 0(x0)       # x9 = 15
        //   0x18: add  x10, x9, x5     # x10 = 20       (load-use: 1-cycle stall then MEM-EX fwd)
        //   0x1C: addi x11, x0, 3      # x11 = 3
        //   0x20: beq  x0, x0, +8      # taken -> PC = 0x28
        //   0x24: addi x12, x0, 99     # SHOULD BE FLUSHED (x12 should stay 0)
        //   0x28: addi x13, x0, 42     # x13 = 42
        //   0x2C: slli x14, x13, 1     # x14 = 84
        //   0x30: ori  x15, x0, 0xFF   # x15 = 255
        //   0x34: nop (end padding)
        // =====================================================================

        // Let pipeline drain — 25 cycles should be more than enough
        repeat (30) begin
            @(posedge clk);
            cycle = cycle + 1;
            $display("--- Cycle %0d | PC=0x%08h | Stall=%b | Flush=%b | FwdA=%b FwdB=%b ---",
                     cycle, pc_val, stall, flush, fwd_a, fwd_b);
        end

        // =====================================================================
        // Verify final register state
        // =====================================================================
        $display("\n===== Register File Verification =====\n");

        check(x0,  32'd0,   "x0  (hardwired)");
        check(x5,  32'd5,   "x5  (addi x5,x0,5)");
        check(x6,  32'd10,  "x6  (addi x6,x0,10)");
        check(x7,  32'd15,  "x7  (add x7,x5,x6)");
        check(x8,  32'd10,  "x8  (sub x8,x7,x5)");
        check(x9,  32'd15,  "x9  (lw x9,0(x0))");
        check(x10, 32'd20,  "x10 (add x10,x9,x5)");
        check(x11, 32'd3,   "x11 (addi x11,x0,3)");
        check(x12, 32'd0,   "x12 (should be flushed)");
        check(x13, 32'd42,  "x13 (addi x13,x0,42)");
        check(x14, 32'd84,  "x14 (slli x14,x13,1)");
        check(x15, 32'd255, "x15 (ori x15,x0,0xFF)");

        // =====================================================================
        // Data memory check: word at addr 0 should be 15
        // =====================================================================
        $display("\n===== Data Memory Verification =====\n");
        begin : mem_check
            reg [31:0] mem_word;
            mem_word = {dut.mem_inst.dmem.memory[3],
                        dut.mem_inst.dmem.memory[2],
                        dut.mem_inst.dmem.memory[1],
                        dut.mem_inst.dmem.memory[0]};
            check(mem_word, 32'd15, "dmem[0] (sw x7,0(x0))");
        end

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n===== Results: %0d passed, %0d failed =====\n", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #5000;
        $display("\n[TIMEOUT] Simulation exceeded 5000ns");
        $finish;
    end

endmodule
