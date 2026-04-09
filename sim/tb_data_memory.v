`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_data_memory
// Description: Tests byte (LB/SB/LBU), halfword (LH/SH/LHU), and word
//              (LW/SW) read/write operations including sign/zero extension.
//////////////////////////////////////////////////////////////////////////////////

module tb_data_memory;

    parameter CLK_HALF = 5;

    reg        clk, mem_read, mem_write;
    reg [31:0] addr, write_data;
    reg [2:0]  funct3;
    wire [31:0] read_data;

    integer pass_count = 0;
    integer fail_count = 0;

    data_memory dut (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (addr),
        .write_data (write_data),
        .funct3     (funct3),
        .read_data  (read_data)
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

    // Helper: do a write, then a read at the same address
    task do_write;
        input [31:0] a;
        input [31:0] d;
        input [2:0]  f;
        begin
            addr = a; write_data = d; funct3 = f;
            mem_write = 1; mem_read = 0;
            @(posedge clk); #1;
            mem_write = 0;
        end
    endtask

    task do_read;
        input [31:0] a;
        input [2:0]  f;
        begin
            addr = a; funct3 = f;
            mem_read = 1; mem_write = 0; #1;
        end
    endtask

    initial begin
        $display("=== tb_data_memory ===");
        clk = 0; mem_read = 0; mem_write = 0;
        addr = 0; write_data = 0; funct3 = 3'b010;
        #1;

        // ---- SW / LW ----
        do_write(32'h00000004, 32'hDEADBEEF, 3'b010);
        do_read(32'h00000004, 3'b010);
        check32(read_data, 32'hDEADBEEF, "LW after SW");

        // ---- SW / LW at address 0 ----
        do_write(32'h00000000, 32'h12345678, 3'b010);
        do_read(32'h00000000, 3'b010);
        check32(read_data, 32'h12345678, "LW addr 0");

        // ---- SB / LB (byte 0, sign-extend) ----
        do_write(32'h00000008, 32'hABCDEF99, 3'b010); // init word
        do_write(32'h00000008, 32'h000000FF, 3'b000); // SB byte 0 = 0xFF
        do_read(32'h00000008, 3'b000); // LB byte 0
        check32(read_data, 32'hFFFFFFFF, "LB sign-extend 0xFF");

        // ---- SB / LBU (byte 0, zero-extend) ----
        do_read(32'h00000008, 3'b100); // LBU
        check32(read_data, 32'h000000FF, "LBU zero-extend 0xFF");

        // ---- SB / LB byte 1 ----
        do_write(32'h00000009, 32'h0000007F, 3'b000); // SB byte 1 = 0x7F
        do_read(32'h00000009, 3'b000);
        check32(read_data, 32'h0000007F, "LB byte1 pos");

        // ---- SH / LH (halfword 0, sign-extend) ----
        do_write(32'h00000010, 32'h0000_8000, 3'b001); // SH half0 = 0x8000
        do_read(32'h00000010, 3'b001);
        check32(read_data, 32'hFFFF8000, "LH sign-extend 0x8000");

        // ---- SH / LHU ----
        do_read(32'h00000010, 3'b101); // LHU
        check32(read_data, 32'h00008000, "LHU zero-extend 0x8000");

        // ---- SH half 1 ----
        do_write(32'h00000012, 32'h00001234, 3'b001); // SH byte offset 2 (half1)
        do_read(32'h00000012, 3'b001);
        check32(read_data, 32'h00001234, "LH half1 pos");

        // ---- no read when mem_read=0 ----
        mem_read = 0; addr = 32'h00000004; funct3 = 3'b010; #1;
        check32(read_data, 32'h0, "read_data=0 when mem_read=0");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
