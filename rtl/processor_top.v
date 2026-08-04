`timescale 1ns / 1ps

module processor_top (
    input clk,
    input reset
);

    // =========================================================================
    // Wire declarations
    // =========================================================================

    // IF stage outputs
    wire [31:0] if_instr;
    wire [31:0] if_pc;

    // Hazard unit outputs
    wire        pc_write_en;
    wire        if_id_write_en;
    wire        id_ex_flush;
    wire        if_id_flush;

    // IF/ID register outputs
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;

    // ID stage outputs
    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [31:0] id_imm;
    wire [4:0]  id_rs1_addr;
    wire [4:0]  id_rs2_addr;
    wire [4:0]  id_rd_addr;
    wire [2:0]  id_funct3;
    wire        id_funct7_bit5;
    wire        id_reg_write;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_alu_src;
    wire [1:0]  id_alu_op;
    wire        id_branch;
    wire        id_jal;
    wire        id_jalr;
    wire [1:0]  id_mem_to_reg;
    wire [1:0]  id_alu_src_a;

    // ID/EX register outputs
    wire        ex_reg_write;
    wire        ex_mem_read;
    wire        ex_mem_write;
    wire        ex_alu_src;
    wire [1:0]  ex_alu_op;
    wire        ex_branch;
    wire        ex_jal;
    wire        ex_jalr;
    wire [1:0]  ex_mem_to_reg;
    wire [1:0]  ex_alu_src_a;
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_imm;
    wire [31:0] ex_pc;
    wire [2:0]  ex_funct3;
    wire        ex_funct7_bit5;
    wire [4:0]  ex_rs1_addr;
    wire [4:0]  ex_rs2_addr;
    wire [4:0]  ex_rd_addr;

    // Forwarding unit outputs
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;

    // EX stage outputs
    wire [31:0] ex_alu_result;
    wire [31:0] ex_rs2_forwarded;
    wire        branch_taken;
    wire [31:0] branch_target;
    wire [31:0] ex_pc_plus4;

    // EX/MEM register outputs
    wire        mem_reg_write;
    wire        mem_mem_read;
    wire        mem_mem_write;
    wire [1:0]  mem_mem_to_reg;
    wire [2:0]  mem_funct3;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_rs2_data;
    wire [31:0] mem_pc_plus4;
    wire [4:0]  mem_rd_addr;

    // MEM stage output
    wire [31:0] mem_read_data;

    // MEM/WB register outputs
    wire        wb_reg_write;
    wire [1:0]  wb_mem_to_reg;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_read_data;
    wire [31:0] wb_pc_plus4;
    wire [4:0]  wb_rd_addr;

    // WB stage output
    wire [31:0] wb_data;

    // =========================================================================
    // IF Stage
    // =========================================================================
    if_stage if_inst (
        .clk(clk),
        .reset(reset),
        .pc_write_en(pc_write_en),
        .branch_target(branch_target),
        .branch_taken(branch_taken),
        .instr_out(if_instr),
        .pc_out(if_pc)
    );

    // =========================================================================
    // IF/ID Pipeline Register
    // =========================================================================
    if_id_reg if_id (
        .clk(clk),
        .reset(reset),
        .write_en(if_id_write_en),
        .flush(if_id_flush),
        .if_pc(if_pc),
        .if_instr(if_instr),
        .id_pc(if_id_pc),
        .id_instr(if_id_instr)
    );

    // =========================================================================
    // ID Stage
    // =========================================================================
    id_stage id_inst (
        .clk(clk),
        .reset(reset),
        .instr(if_id_instr),
        .pc(if_id_pc),
        .wb_reg_write(wb_reg_write),
        .wb_rd(wb_rd_addr),
        .wb_data(wb_data),
        .rs1_data(id_rs1_data),
        .rs2_data(id_rs2_data),
        .imm(id_imm),
        .rs1_addr(id_rs1_addr),
        .rs2_addr(id_rs2_addr),
        .rd_addr(id_rd_addr),
        .funct3(id_funct3),
        .funct7_bit5(id_funct7_bit5),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .alu_src(id_alu_src),
        .alu_op(id_alu_op),
        .branch(id_branch),
        .jal(id_jal),
        .jalr(id_jalr),
        .mem_to_reg(id_mem_to_reg),
        .alu_src_a(id_alu_src_a)
    );

    // =========================================================================
    // ID/EX Pipeline Register
    // =========================================================================
    id_ex_reg id_ex (
        .clk(clk),
        .reset(reset),
        .flush(id_ex_flush),
        // Control in
        .id_reg_write(id_reg_write),
        .id_mem_read(id_mem_read),
        .id_mem_write(id_mem_write),
        .id_alu_src(id_alu_src),
        .id_alu_op(id_alu_op),
        .id_branch(id_branch),
        .id_jal(id_jal),
        .id_jalr(id_jalr),
        .id_mem_to_reg(id_mem_to_reg),
        .id_alu_src_a(id_alu_src_a),
        // Data in
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_imm(id_imm),
        .id_pc(if_id_pc),
        .id_funct3(id_funct3),
        .id_funct7_bit5(id_funct7_bit5),
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .id_rd_addr(id_rd_addr),
        // Control out
        .ex_reg_write(ex_reg_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_alu_src(ex_alu_src),
        .ex_alu_op(ex_alu_op),
        .ex_branch(ex_branch),
        .ex_jal(ex_jal),
        .ex_jalr(ex_jalr),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_alu_src_a(ex_alu_src_a),
        // Data out
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_imm(ex_imm),
        .ex_pc(ex_pc),
        .ex_funct3(ex_funct3),
        .ex_funct7_bit5(ex_funct7_bit5),
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .ex_rd_addr(ex_rd_addr)
    );

    // =========================================================================
    // Forwarding Unit
    // =========================================================================
    forwarding_unit fwd_unit (
        .id_ex_rs1(ex_rs1_addr),
        .id_ex_rs2(ex_rs2_addr),
        .ex_mem_rd(mem_rd_addr),
        .ex_mem_reg_write(mem_reg_write),
        .ex_mem_mem_to_reg(mem_mem_to_reg),
        .mem_wb_rd(wb_rd_addr),
        .mem_wb_reg_write(wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // =========================================================================
    // EX Stage
    // =========================================================================
    ex_stage ex_inst (
        .rs1_data(ex_rs1_data),
        .rs2_data(ex_rs2_data),
        .imm(ex_imm),
        .pc(ex_pc),
        .funct3(ex_funct3),
        .funct7_bit5(ex_funct7_bit5),
        .alu_op(ex_alu_op),
        .alu_src(ex_alu_src),
        .alu_src_a(ex_alu_src_a),
        .branch(ex_branch),
        .jal(ex_jal),
        .jalr(ex_jalr),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .ex_mem_alu_result(mem_alu_result),
        .wb_data(wb_data),
        .alu_result(ex_alu_result),
        .rs2_forwarded(ex_rs2_forwarded),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .pc_plus4(ex_pc_plus4)
    );

    // =========================================================================
    // EX/MEM Pipeline Register
    // =========================================================================
    ex_mem_reg ex_mem (
        .clk(clk),
        .reset(reset),
        .ex_reg_write(ex_reg_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_funct3(ex_funct3),
        .ex_alu_result(ex_alu_result),
        .ex_rs2_forwarded(ex_rs2_forwarded),
        .ex_pc_plus4(ex_pc_plus4),
        .ex_rd_addr(ex_rd_addr),
        .mem_reg_write(mem_reg_write),
        .mem_mem_read(mem_mem_read),
        .mem_mem_write(mem_mem_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_funct3(mem_funct3),
        .mem_alu_result(mem_alu_result),
        .mem_rs2_data(mem_rs2_data),
        .mem_pc_plus4(mem_pc_plus4),
        .mem_rd_addr(mem_rd_addr)
    );

    // =========================================================================
    // MEM Stage
    // =========================================================================
    mem_stage mem_inst (
        .clk(clk),
        .mem_read(mem_mem_read),
        .mem_write(mem_mem_write),
        .funct3(mem_funct3),
        .alu_result(mem_alu_result),
        .write_data(mem_rs2_data),
        .read_data(mem_read_data)
    );

    // =========================================================================
    // MEM/WB Pipeline Register
    // =========================================================================
    mem_wb_reg mem_wb (
        .clk(clk),
        .reset(reset),
        .mem_reg_write(mem_reg_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_alu_result(mem_alu_result),
        .mem_read_data(mem_read_data),
        .mem_pc_plus4(mem_pc_plus4),
        .mem_rd_addr(mem_rd_addr),
        .wb_reg_write(wb_reg_write),
        .wb_mem_to_reg(wb_mem_to_reg),
        .wb_alu_result(wb_alu_result),
        .wb_read_data(wb_read_data),
        .wb_pc_plus4(wb_pc_plus4),
        .wb_rd_addr(wb_rd_addr)
    );

    // =========================================================================
    // WB Stage
    // =========================================================================
    wb_stage wb_inst (
        .mem_to_reg(wb_mem_to_reg),
        .alu_result(wb_alu_result),
        .read_data(wb_read_data),
        .pc_plus4(wb_pc_plus4),
        .wb_data(wb_data)
    );

    // =========================================================================
    // Hazard Detection Unit
    // =========================================================================
    hazard_unit haz_unit (
        .id_ex_mem_read(ex_mem_read),
        .id_ex_rd(ex_rd_addr),
        .if_id_rs1(if_id_instr[19:15]),
        .if_id_rs2(if_id_instr[24:20]),
        .if_id_opcode(if_id_instr[6:0]),
        .branch_taken(branch_taken),
        .pc_write_en(pc_write_en),
        .if_id_write_en(if_id_write_en),
        .id_ex_flush(id_ex_flush),
        .if_id_flush(if_id_flush)
    );

endmodule
