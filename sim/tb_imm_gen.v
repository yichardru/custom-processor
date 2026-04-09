`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_imm_gen
// Description: Verifies sign-/zero-extension for every RV32I immediate format.
//////////////////////////////////////////////////////////////////////////////////

module tb_imm_gen;

    reg  [31:0] instr;
    wire [31:0] imm;

    integer pass_count = 0;
    integer fail_count = 0;

    imm_gen dut (.instr(instr), .imm(imm));

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
        $display("=== tb_imm_gen ===");

        // ---- I-type positive: ADDI x1, x0, 5 (imm=5) ----
        // opcode=0010011, rd=00001, funct3=000, rs1=00000, imm[11:0]=000000000101
        instr = 32'b000000000101_00000_000_00001_0010011; #1;
        check32(imm, 32'd5, "I-type pos +5");

        // ---- I-type negative: ADDI x1, x0, -1 (imm=0xFFF) ----
        instr = 32'b111111111111_00000_000_00001_0010011; #1;
        check32(imm, 32'hFFFFFFFF, "I-type neg -1");

        // ---- I-type JALR: imm=0x7FF ----
        instr = {12'h7FF, 5'd0, 3'b000, 5'd1, 7'b1100111}; #1;
        check32(imm, 32'h000007FF, "I-JALR max pos");

        // ---- S-type positive: SW  (imm=0x10) ----
        // imm[11:5]=0000001, imm[4:0]=10000
        instr = {7'b0000001, 5'd1, 5'd0, 3'b010, 5'b10000, 7'b0100011}; #1;
        check32(imm, 32'h00000030, "S-type +0x30"); // 0b0000001_10000 = 0x30

        // ---- S-type negative: SW  (all-ones imm = -1) ----
        instr = {7'b1111111, 5'd1, 5'd0, 3'b010, 5'b11111, 7'b0100011}; #1;
        check32(imm, 32'hFFFFFFFF, "S-type -1");

        // ---- B-type: BEQ  imm=+8 ----
        // imm[12]=0 imm[10:5]=000001 rs2=00001 rs1=00000 funct3=000 imm[4:1]=0000 imm[11]=0
        instr = {1'b0, 6'b000001, 5'd1, 5'd0, 3'b000, 4'b0000, 1'b0, 7'b1100011}; #1;
        check32(imm, 32'd32, "B-type +32"); // 0_0_000001_0000_0 = 32

        // ---- B-type: BEQ negative ----
        instr = {1'b1, 6'b111111, 5'd1, 5'd0, 3'b000, 4'b1111, 1'b1, 7'b1100011}; #1;
        check32(imm, 32'hFFFFFFFE, "B-type -2");

        // ---- U-type: LUI x1, 0x12345 ----
        instr = {20'h12345, 5'd1, 7'b0110111}; #1;
        check32(imm, 32'h12345000, "U-type LUI 0x12345000");

        // ---- U-type: LUI with MSB set ----
        instr = {20'hFFFFF, 5'd1, 7'b0110111}; #1;
        check32(imm, 32'hFFFFF000, "U-type LUI MSB");

        // ---- J-type: JAL  imm=+4 ----
        // imm[20]=0 imm[10:1]=0000000001 imm[11]=0 imm[19:12]=00000000
        instr = {1'b0, 10'b0000000001, 1'b0, 8'b00000000, 5'd1, 7'b1101111}; #1;
        check32(imm, 32'd2, "J-type +2"); // bit0 always 0, so encoded 1 → actual 2

        // ---- J-type: JAL negative ----
        instr = {1'b1, 10'b1111111111, 1'b1, 8'b11111111, 5'd1, 7'b1101111}; #1;
        check32(imm, 32'hFFFFFFFE, "J-type -2");

        // ---- Unknown opcode → 0 ----
        instr = 32'h00000000; #1;
        check32(imm, 32'h0, "Unknown 0");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
