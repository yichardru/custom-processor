`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_alu_ctrl
// Description: Exercises every combination of alu_op and funct3/funct7 to
//              confirm the ALU control decoder produces the correct opcode.
//////////////////////////////////////////////////////////////////////////////////

module tb_alu_ctrl;

    reg  [1:0] alu_op;
    reg  [2:0] funct3;
    reg        funct7b5;
    reg        opcode5;
    wire [3:0] alu_ctrl_out;

    integer pass_count = 0;
    integer fail_count = 0;

    alu_ctrl dut (
        .alu_op      (alu_op),
        .funct3      (funct3),
        .funct7b5    (funct7b5),
        .opcode5     (opcode5),
        .alu_ctrl_out(alu_ctrl_out)
    );

    task check;
        input [3:0] got;
        input [3:0] exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got %04b, expected %04b",
                         $time, name, got, exp);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_alu_ctrl ===");

        // alu_op=00 → always ADD
        alu_op=2'b00; funct3=3'b000; funct7b5=0; opcode5=0; #1;
        check(alu_ctrl_out, 4'b0000, "alu_op=00 ADD");

        // alu_op=01 → always SUB
        alu_op=2'b01; funct3=3'b111; funct7b5=1; opcode5=0; #1;
        check(alu_ctrl_out, 4'b0001, "alu_op=01 SUB");

        // alu_op=11 → always PASSB
        alu_op=2'b11; funct3=3'b000; funct7b5=0; opcode5=0; #1;
        check(alu_ctrl_out, 4'b1010, "alu_op=11 PASSB");

        // alu_op=10, funct3=000: R-type with funct7b5=1 → SUB
        alu_op=2'b10; funct3=3'b000; funct7b5=1; opcode5=1; #1;
        check(alu_ctrl_out, 4'b0001, "R-type SUB");

        // alu_op=10, funct3=000: R-type with funct7b5=0 → ADD
        alu_op=2'b10; funct3=3'b000; funct7b5=0; opcode5=1; #1;
        check(alu_ctrl_out, 4'b0000, "R-type ADD");

        // alu_op=10, funct3=000: I-type (opcode5=0) always ADD even if funct7b5=1
        alu_op=2'b10; funct3=3'b000; funct7b5=1; opcode5=0; #1;
        check(alu_ctrl_out, 4'b0000, "I-type ADDI (funct7b5 ignored)");

        // funct3=001 → SLL
        alu_op=2'b10; funct3=3'b001; funct7b5=0; opcode5=1; #1;
        check(alu_ctrl_out, 4'b0101, "SLL");

        // funct3=010 → SLT
        alu_op=2'b10; funct3=3'b010; funct7b5=0; opcode5=1; #1;
        check(alu_ctrl_out, 4'b1000, "SLT");

        // funct3=011 → SLTU
        alu_op=2'b10; funct3=3'b011; funct7b5=0; opcode5=1; #1;
        check(alu_ctrl_out, 4'b1001, "SLTU");

        // funct3=100 → XOR
        alu_op=2'b10; funct3=3'b100; funct7b5=0; opcode5=1; #1;
        check(alu_ctrl_out, 4'b0100, "XOR");

        // funct3=101, funct7b5=0 → SRL
        alu_op=2'b10; funct3=3'b101; funct7b5=0; opcode5=1; #1;
        check(alu_ctrl_out, 4'b0110, "SRL");

        // funct3=101, funct7b5=1 → SRA
        alu_op=2'b10; funct3=3'b101; funct7b5=1; opcode5=1; #1;
        check(alu_ctrl_out, 4'b0111, "SRA");

        // funct3=110 → OR
        alu_op=2'b10; funct3=3'b110; funct7b5=0; opcode5=1; #1;
        check(alu_ctrl_out, 4'b0011, "OR");

        // funct3=111 → AND
        alu_op=2'b10; funct3=3'b111; funct7b5=0; opcode5=1; #1;
        check(alu_ctrl_out, 4'b0010, "AND");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
