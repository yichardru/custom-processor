`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_control_unit
// Description: Verifies that the control unit produces the correct set of
//              control signals for every RV32I opcode.
//////////////////////////////////////////////////////////////////////////////////

module tb_control_unit;

    reg  [6:0] opcode;
    wire       reg_write, alu_src_b, alu_src_a;
    wire       mem_read, mem_write;
    wire [1:0] mem_to_reg;
    wire       branch, jump, jalr;
    wire [1:0] alu_op;

    integer pass_count = 0;
    integer fail_count = 0;

    control_unit dut (
        .opcode    (opcode),
        .reg_write (reg_write),
        .alu_src_b (alu_src_b),
        .alu_src_a (alu_src_a),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .mem_to_reg(mem_to_reg),
        .branch    (branch),
        .jump      (jump),
        .jalr      (jalr),
        .alu_op    (alu_op)
    );

    // Helper task: check one output bit
    task check;
        input [63:0] got;
        input [63:0] exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got %0b, expected %0b", $time, name, got, exp);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("=== tb_control_unit ===");

        // ------- R-type (ADD/SUB/AND/OR/…) -------
        opcode = 7'b0110011; #1;
        check(reg_write, 1, "R reg_write");
        check(alu_src_b, 0, "R alu_src_b");
        check(alu_src_a, 0, "R alu_src_a");
        check(mem_read,  0, "R mem_read");
        check(mem_write, 0, "R mem_write");
        check(mem_to_reg,0, "R mem_to_reg");
        check(branch,    0, "R branch");
        check(jump,      0, "R jump");
        check(alu_op,    2'b10, "R alu_op");

        // ------- I-type ALU (ADDI/ANDI/…) -------
        opcode = 7'b0010011; #1;
        check(reg_write, 1,    "I reg_write");
        check(alu_src_b, 1,    "I alu_src_b");
        check(alu_src_a, 0,    "I alu_src_a");
        check(mem_read,  0,    "I mem_read");
        check(mem_write, 0,    "I mem_write");
        check(mem_to_reg,0,    "I mem_to_reg");
        check(branch,    0,    "I branch");
        check(jump,      0,    "I jump");
        check(alu_op,    2'b10,"I alu_op");

        // ------- Load -------
        opcode = 7'b0000011; #1;
        check(reg_write, 1,    "Load reg_write");
        check(alu_src_b, 1,    "Load alu_src_b");
        check(mem_read,  1,    "Load mem_read");
        check(mem_write, 0,    "Load mem_write");
        check(mem_to_reg,2'b01,"Load mem_to_reg");
        check(branch,    0,    "Load branch");
        check(alu_op,    2'b00,"Load alu_op");

        // ------- Store -------
        opcode = 7'b0100011; #1;
        check(reg_write, 0,    "Store reg_write");
        check(alu_src_b, 1,    "Store alu_src_b");
        check(mem_read,  0,    "Store mem_read");
        check(mem_write, 1,    "Store mem_write");
        check(branch,    0,    "Store branch");
        check(alu_op,    2'b00,"Store alu_op");

        // ------- Branch -------
        opcode = 7'b1100011; #1;
        check(reg_write, 0,    "Branch reg_write");
        check(alu_src_b, 0,    "Branch alu_src_b");
        check(mem_read,  0,    "Branch mem_read");
        check(mem_write, 0,    "Branch mem_write");
        check(branch,    1,    "Branch branch");
        check(jump,      0,    "Branch jump");
        check(alu_op,    2'b01,"Branch alu_op");

        // ------- LUI -------
        opcode = 7'b0110111; #1;
        check(reg_write, 1,    "LUI reg_write");
        check(alu_src_b, 1,    "LUI alu_src_b");
        check(alu_src_a, 0,    "LUI alu_src_a");
        check(mem_read,  0,    "LUI mem_read");
        check(alu_op,    2'b11,"LUI alu_op");

        // ------- AUIPC -------
        opcode = 7'b0010111; #1;
        check(reg_write, 1,    "AUIPC reg_write");
        check(alu_src_b, 1,    "AUIPC alu_src_b");
        check(alu_src_a, 1,    "AUIPC alu_src_a");
        check(mem_read,  0,    "AUIPC mem_read");
        check(alu_op,    2'b00,"AUIPC alu_op");

        // ------- JAL -------
        opcode = 7'b1101111; #1;
        check(reg_write, 1,    "JAL reg_write");
        check(alu_src_a, 1,    "JAL alu_src_a");
        check(alu_src_b, 1,    "JAL alu_src_b");
        check(jump,      1,    "JAL jump");
        check(jalr,      0,    "JAL jalr");
        check(mem_to_reg,2'b10,"JAL mem_to_reg");
        check(alu_op,    2'b00,"JAL alu_op");

        // ------- JALR -------
        opcode = 7'b1100111; #1;
        check(reg_write, 1,    "JALR reg_write");
        check(alu_src_a, 0,    "JALR alu_src_a");
        check(alu_src_b, 1,    "JALR alu_src_b");
        check(jump,      1,    "JALR jump");
        check(jalr,      1,    "JALR jalr");
        check(mem_to_reg,2'b10,"JALR mem_to_reg");
        check(alu_op,    2'b00,"JALR alu_op");

        // ------- Unknown opcode -------
        opcode = 7'b0000000; #1;
        check(reg_write, 0, "Unknown reg_write");
        check(mem_read,  0, "Unknown mem_read");
        check(mem_write, 0, "Unknown mem_write");
        check(branch,    0, "Unknown branch");
        check(jump,      0, "Unknown jump");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end

endmodule
