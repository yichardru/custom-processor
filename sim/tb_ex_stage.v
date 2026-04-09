`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_ex_stage
// Description: Tests the EX stage in isolation:
//   • Basic ALU operations without forwarding.
//   • forwardA / forwardB mux selection.
//   • Branch condition evaluation for all six branch types.
//   • Jump (JAL / JALR) branch_taken and target generation.
//   • LUI (PASSB) and AUIPC (PC+imm).
//////////////////////////////////////////////////////////////////////////////////

module tb_ex_stage;

    // ---  EX stage inputs ---
    reg [31:0] rs1_data, rs2_data, imm, pc;
    reg [4:0]  rd_addr;
    reg [2:0]  funct3;
    reg        funct7b5, alu_src_a, alu_src_b;
    reg        branch, jump, jalr;
    reg [1:0]  alu_op;
    reg [1:0]  forwardA, forwardB;
    reg [31:0] ex_mem_alu_result, wb_data;

    // --- outputs ---
    wire [31:0] alu_result, rs2_fwd_data;
    wire [4:0]  rd_addr_out;
    wire        branch_taken;
    wire [31:0] branch_target;

    integer pass_count = 0;
    integer fail_count = 0;

    ex_stage dut (
        .rs1_data         (rs1_data),
        .rs2_data         (rs2_data),
        .imm              (imm),
        .pc               (pc),
        .rd_addr          (rd_addr),
        .funct3           (funct3),
        .funct7b5         (funct7b5),
        .alu_src_a        (alu_src_a),
        .alu_src_b        (alu_src_b),
        .branch           (branch),
        .jump             (jump),
        .jalr             (jalr),
        .alu_op           (alu_op),
        .forwardA         (forwardA),
        .forwardB         (forwardB),
        .ex_mem_alu_result(ex_mem_alu_result),
        .wb_data          (wb_data),
        .alu_result       (alu_result),
        .rs2_fwd_data     (rs2_fwd_data),
        .rd_addr_out      (rd_addr_out),
        .branch_taken     (branch_taken),
        .branch_target    (branch_target)
    );

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

    task check1;
        input got;
        input exp;
        input [127:0] name;
        begin
            if (got !== exp) begin
                $display("FAIL [%0t] %s: got %b, exp %b",
                         $time, name, got, exp);
                fail_count = fail_count + 1;
            end else
                pass_count = pass_count + 1;
        end
    endtask

    // Default inactive settings
    task set_defaults;
        begin
            rs1_data=0; rs2_data=0; imm=0; pc=0;
            rd_addr=0; funct3=0; funct7b5=0;
            alu_src_a=0; alu_src_b=0;
            branch=0; jump=0; jalr=0;
            alu_op=2'b00;
            forwardA=2'b00; forwardB=2'b00;
            ex_mem_alu_result=0; wb_data=0;
        end
    endtask

    initial begin
        $display("=== tb_ex_stage ===");
        set_defaults;

        // ---- R-type ADD: rs1=10, rs2=5 → alu_result=15 ----
        rs1_data=32'd10; rs2_data=32'd5;
        alu_src_a=0; alu_src_b=0; alu_op=2'b10;
        funct3=3'b000; funct7b5=0; // ADD
        #1;
        check32(alu_result, 32'd15,       "R-ADD result");
        check32(rs2_fwd_data, 32'd5,      "R-ADD rs2_fwd_data");
        check1(branch_taken, 0,           "R-ADD no branch");

        // ---- I-type ADDI: rs1=100, imm=42 ----
        rs1_data=32'd100; imm=32'd42;
        alu_src_b=1; alu_op=2'b10;
        funct3=3'b000; funct7b5=0;
        #1;
        check32(alu_result, 32'd142, "ADDI result");

        // ---- LUI: PASSB, imm=0x12345000 ----
        imm=32'h12345000; alu_src_b=1; alu_op=2'b11; #1;
        check32(alu_result, 32'h12345000, "LUI passb");

        // ---- AUIPC: PC + imm ----
        pc=32'h00000100; imm=32'h00001000;
        alu_src_a=1; alu_src_b=1; alu_op=2'b00; #1;
        check32(alu_result, 32'h00001100, "AUIPC result");

        // ---- Forwarding: forwardA = 2'b10 (EX/MEM) ----
        set_defaults;
        rs1_data=32'd1; ex_mem_alu_result=32'hABCD0000;
        forwardA=2'b10; alu_op=2'b10; funct3=3'b000; funct7b5=0;
        rs2_data=32'd1;
        #1;
        check32(alu_result, 32'hABCD0001, "forwardA EX/MEM + rs2");

        // ---- Forwarding: forwardB = 2'b01 (MEM/WB) ----
        set_defaults;
        rs1_data=32'd10; rs2_data=32'd0; wb_data=32'd7;
        forwardB=2'b01; alu_op=2'b10; funct3=3'b000; funct7b5=0; #1;
        check32(alu_result, 32'd17, "forwardB MEM/WB + rs1");
        check32(rs2_fwd_data, 32'd7, "forwardB rs2_fwd_data=wb_data");

        // ---- BEQ taken: rs1 == rs2 ----
        set_defaults;
        rs1_data=32'd5; rs2_data=32'd5;
        pc=32'h20; imm=32'h8; // target = 0x28
        branch=1; funct3=3'b000; alu_op=2'b01; #1;
        check1(branch_taken, 1,          "BEQ taken");
        check32(branch_target, 32'h28,   "BEQ target");

        // ---- BEQ not taken: rs1 != rs2 ----
        rs1_data=32'd5; rs2_data=32'd6; #1;
        check1(branch_taken, 0, "BEQ not taken");

        // ---- BNE taken ----
        rs1_data=32'd1; rs2_data=32'd2; funct3=3'b001; #1;
        check1(branch_taken, 1, "BNE taken");

        // ---- BLT (signed) taken: -1 < 0 ----
        rs1_data=32'hFFFFFFFF; rs2_data=32'd0; funct3=3'b100; #1;
        check1(branch_taken, 1, "BLT signed taken");

        // ---- BGE (signed) taken: 0 >= -1 ----
        rs1_data=32'd0; rs2_data=32'hFFFFFFFF; funct3=3'b101; #1;
        check1(branch_taken, 1, "BGE signed taken");

        // ---- BLTU (unsigned) taken: 1 < 0xFFFFFFFF ----
        rs1_data=32'd1; rs2_data=32'hFFFFFFFF; funct3=3'b110; #1;
        check1(branch_taken, 1, "BLTU taken");

        // ---- BGEU (unsigned) taken: 0xFFFFFFFF >= 1 ----
        rs1_data=32'hFFFFFFFF; rs2_data=32'd1; funct3=3'b111; #1;
        check1(branch_taken, 1, "BGEU taken");

        // ---- JAL: jump=1, target = PC + imm ----
        set_defaults;
        pc=32'h100; imm=32'h40;
        alu_src_a=1; alu_src_b=1; alu_op=2'b00;
        jump=1; jalr=0; #1;
        check1(branch_taken, 1,         "JAL taken");
        check32(branch_target, 32'h140, "JAL target PC+imm");

        // ---- JALR: target = (rs1+imm) & ~1 ----
        set_defaults;
        rs1_data=32'h100; imm=32'h5;  // rs1+imm=0x105, bit0 cleared = 0x104
        alu_src_a=0; alu_src_b=1; alu_op=2'b00;
        jump=1; jalr=1; #1;
        check1(branch_taken, 1,         "JALR taken");
        check32(branch_target, 32'h104, "JALR target rs1+imm&~1");

        $display("Result: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) $display("PASS"); else $display("FAIL");
        $finish;
    end

endmodule
