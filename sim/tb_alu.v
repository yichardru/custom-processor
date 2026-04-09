`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_alu
// Description: Verifies every ALU operation including flags (zero, negative,
//              overflow, carry) used by the branch logic.
//////////////////////////////////////////////////////////////////////////////////

module tb_alu;

    reg  [31:0] a, b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero, negative, overflow, carry;

    integer pass_count = 0;
    integer fail_count = 0;

    alu dut (
        .a(a), .b(b), .alu_ctrl(alu_ctrl),
        .result(result), .zero(zero),
        .negative(negative), .overflow(overflow), .carry(carry)
    );

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

    task check1;
        input got;
        input exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got %b, expected %b",
                         $time, name, got, exp);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_alu ===");

        // ---- ADD ----
        alu_ctrl = 4'b0000;
        a=32'd10; b=32'd5; #1;
        check32(result, 32'd15, "ADD 10+5");
        check1(zero,    0,      "ADD 10+5 zero");
        check1(carry,   0,      "ADD no carry");
        check1(overflow,0,      "ADD no overflow");

        // ADD producing zero
        a=32'd0; b=32'd0; #1;
        check32(result, 32'd0, "ADD 0+0");
        check1(zero, 1, "ADD 0+0 zero=1");

        // ADD carry (unsigned overflow)
        a=32'hFFFFFFFF; b=32'd1; #1;
        check32(result, 32'd0, "ADD wrap to 0");
        check1(carry, 1, "ADD carry=1");
        check1(zero,  1, "ADD wrap zero=1");

        // ADD signed overflow (pos+pos=neg)
        a=32'h7FFFFFFF; b=32'd1; #1;
        check1(overflow, 1, "ADD signed overflow");
        check1(negative, 1, "ADD result negative");

        // ---- SUB ----
        alu_ctrl = 4'b0001;
        a=32'd15; b=32'd5; #1;
        check32(result, 32'd10, "SUB 15-5=10");
        check1(zero,  0, "SUB nonzero");
        check1(carry, 1, "SUB a>=b carry=1");

        // SUB equal → zero, carry=1
        a=32'd7; b=32'd7; #1;
        check32(result, 32'd0, "SUB 7-7=0");
        check1(zero,  1, "SUB zero=1");
        check1(carry, 1, "SUB a==b carry=1");

        // SUB a<b (unsigned) → carry=0 (borrow)
        a=32'd3; b=32'd5; #1;
        check1(carry, 0, "SUB a<b carry=0");

        // SUB signed overflow (neg - pos = pos)
        a=32'h80000000; b=32'd1; #1;
        check1(overflow, 1, "SUB signed overflow");

        // ---- AND ----
        alu_ctrl = 4'b0010;
        a=32'hFF00FF00; b=32'h0F0F0F0F; #1;
        check32(result, 32'h0F000F00, "AND");

        // ---- OR ----
        alu_ctrl = 4'b0011;
        a=32'hF0F0F0F0; b=32'h0F0F0F0F; #1;
        check32(result, 32'hFFFFFFFF, "OR");

        // ---- XOR ----
        alu_ctrl = 4'b0100;
        a=32'hAAAAAAAA; b=32'h55555555; #1;
        check32(result, 32'hFFFFFFFF, "XOR");
        a=32'hAAAAAAAA; b=32'hAAAAAAAA; #1;
        check32(result, 32'h0, "XOR self=0");
        check1(zero, 1, "XOR zero=1");

        // ---- SLL ----
        alu_ctrl = 4'b0101;
        a=32'd1; b=32'd4; #1;
        check32(result, 32'd16, "SLL 1<<4=16");
        a=32'h00000001; b=32'd31; #1;
        check32(result, 32'h80000000, "SLL 1<<31");

        // ---- SRL ----
        alu_ctrl = 4'b0110;
        a=32'h80000000; b=32'd1; #1;
        check32(result, 32'h40000000, "SRL MSB>>1");
        a=32'hFFFFFFFF; b=32'd4; #1;
        check32(result, 32'h0FFFFFFF, "SRL logical");

        // ---- SRA ----
        alu_ctrl = 4'b0111;
        a=32'h80000000; b=32'd1; #1;
        check32(result, 32'hC0000000, "SRA MSB sign extend");
        a=32'h7FFFFFFF; b=32'd1; #1;
        check32(result, 32'h3FFFFFFF, "SRA pos no sign ext");

        // ---- SLT (signed) ----
        alu_ctrl = 4'b1000;
        a=32'd1; b=32'd2; #1;
        check32(result, 32'd1, "SLT 1<2=1");
        a=32'd2; b=32'd2; #1;
        check32(result, 32'd0, "SLT 2==2=0");
        a=32'hFFFFFFFF; b=32'd0; #1; // -1 < 0 signed
        check32(result, 32'd1, "SLT -1<0 signed=1");
        a=32'd0; b=32'hFFFFFFFF; #1; // 0 > -1 signed
        check32(result, 32'd0, "SLT 0>-1 signed=0");

        // ---- SLTU (unsigned) ----
        alu_ctrl = 4'b1001;
        a=32'd1; b=32'd2; #1;
        check32(result, 32'd1, "SLTU 1<2=1");
        a=32'hFFFFFFFF; b=32'd0; #1; // large unsigned > 0
        check32(result, 32'd0, "SLTU big>0=0");
        a=32'd0; b=32'hFFFFFFFF; #1;
        check32(result, 32'd1, "SLTU 0<big=1");

        // ---- PASSB (LUI) ----
        alu_ctrl = 4'b1010;
        a=32'hDEADBEEF; b=32'h12345000; #1;
        check32(result, 32'h12345000, "PASSB = b");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
