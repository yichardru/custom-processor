`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_reg_file
// Description: Verifies read/write behavior, x0 hardwiring,
//              and write-before-read bypass.
//////////////////////////////////////////////////////////////////////////////////

module tb_reg_file;

    parameter CLK_HALF = 5;

    reg         clk, reset;
    reg         we;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] wd;
    wire [31:0] rd1, rd2;

    integer pass_count = 0;
    integer fail_count = 0;

    reg_file dut (
        .clk(clk), .reset(reset),
        .we(we), .rs1(rs1), .rs2(rs2), .rd(rd), .wd(wd),
        .rd1(rd1), .rd2(rd2)
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
        $display("=== tb_reg_file ===");
        clk = 0; reset = 1; we = 0;
        rs1 = 0; rs2 = 0; rd = 0; wd = 0;
        @(posedge clk); #1;

        // Release reset
        reset = 0;

        // --- All registers should read 0 after reset ---
        rs1 = 5'd1; rs2 = 5'd31; #1;
        check32(rd1, 32'h0, "reset x1=0");
        check32(rd2, 32'h0, "reset x31=0");

        // --- Write x1 = 0xDEAD_BEEF ---
        we = 1; rd = 5'd1; wd = 32'hDEADBEEF;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd1; #1;
        check32(rd1, 32'hDEADBEEF, "x1 after write");

        // --- Write x2 = 0xCAFEBABE ---
        we = 1; rd = 5'd2; wd = 32'hCAFEBABE;
        @(posedge clk); #1;
        we = 0;
        rs2 = 5'd2; #1;
        check32(rd2, 32'hCAFEBABE, "x2 after write");

        // --- x0 must always read 0, even when written ---
        we = 1; rd = 5'd0; wd = 32'hFFFFFFFF;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd0; #1;
        check32(rd1, 32'h0, "x0 hardwired to 0");

        // --- Write-before-read bypass: read rd during the same cycle as write ---
        we = 1; rd = 5'd5; wd = 32'hABCD1234;
        rs1 = 5'd5; rs2 = 5'd5; #1; // combinational read during write cycle
        check32(rd1, 32'hABCD1234, "WBR bypass rd1");
        check32(rd2, 32'hABCD1234, "WBR bypass rd2");
        @(posedge clk); #1;
        we = 0;

        // --- Verify bypass does NOT activate when rd != rs ---
        rs1 = 5'd1; rs2 = 5'd2;
        we = 1; rd = 5'd5; wd = 32'h11111111; #1;
        check32(rd1, 32'hDEADBEEF, "no bypass x1 reads old");
        check32(rd2, 32'hCAFEBABE, "no bypass x2 reads old");
        @(posedge clk); #1;
        we = 0;

        // --- Two simultaneous reads from different registers ---
        rs1 = 5'd1; rs2 = 5'd2; #1;
        check32(rd1, 32'hDEADBEEF, "rd1 x1");
        check32(rd2, 32'hCAFEBABE, "rd2 x2");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
