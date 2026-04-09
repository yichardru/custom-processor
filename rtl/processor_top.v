`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: processor_top
// Description: Top-level 5-stage pipelined RV32I processor.
//
// Pipeline stages:
//   IF  – Instruction Fetch  (if_stage)
//   ID  – Instruction Decode (id_stage)
//   EX  – Execute            (ex_stage)
//   MEM – Memory Access      (mem_stage)
//   WB  – Write Back         (wb_stage)
//
// Hazard handling:
//   • Load-use stall    – detected and controlled by hazard_unit
//   • Data forwarding   – EX/MEM → EX and MEM/WB → EX paths
//   • Branch flush      – both IF/ID and ID/EX flushed when branch_taken
//
// Memory:
//   • Separate instruction memory (instr_memory, loaded from program.mem)
//   • Separate data memory        (data_memory, 1 KB SRAM)
//////////////////////////////////////////////////////////////////////////////////

module processor_top (
    input clk,
    input reset
);

    // ====================================================================== //
    //  Hazard / forwarding wires (declared early – used throughout)
    // ====================================================================== //
    wire        pc_write_en;
    wire        if_id_write_en;
    wire        id_ex_flush;
    wire        if_id_flush;
    wire [1:0]  forwardA;
    wire [1:0]  forwardB;

    // ====================================================================== //
    //  IF stage
    // ====================================================================== //
    wire [31:0] if_instr;
    wire [31:0] if_pc;

    wire        branch_taken;   // from EX stage
    wire [31:0] branch_target;  // from EX stage

    if_stage if_inst (
        .clk          (clk),
        .reset        (reset),
        .pc_write_en  (pc_write_en),
        .branch_target(branch_target),
        .branch_taken (branch_taken),
        .instr_out    (if_instr),
        .pc_out       (if_pc)
    );

    // PC+4 from IF – needed for JAL/JALR in the pipeline
    wire [31:0] if_pc_plus4 = if_pc + 32'd4;

    // ====================================================================== //
    //  IF/ID pipeline register
    // ====================================================================== //
    wire [31:0] ifid_instr;
    wire [31:0] ifid_pc;

    if_id_reg if_id (
        .clk      (clk),
        .reset    (reset),
        .flush    (if_id_flush),
        .write_en (if_id_write_en),
        .instr_in (if_instr),
        .pc_in    (if_pc),
        .instr_out(ifid_instr),
        .pc_out   (ifid_pc)
    );

    // ====================================================================== //
    //  ID stage
    // ====================================================================== //
    wire [31:0] id_rs1_data, id_rs2_data, id_imm;
    wire [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    wire [2:0]  id_funct3;
    wire        id_funct7b5;
    wire        id_reg_write, id_alu_src_b, id_alu_src_a;
    wire        id_mem_read, id_mem_write;
    wire [1:0]  id_mem_to_reg;
    wire        id_branch, id_jump, id_jalr;
    wire [1:0]  id_alu_op;

    // WB stage write-back (declared later, used here for register file)
    wire        wb_reg_write_sig;
    wire [4:0]  wb_rd_sig;
    wire [31:0] wb_data_sig;

    id_stage id_inst (
        .clk          (clk),
        .reset        (reset),
        .instr        (ifid_instr),
        .pc           (ifid_pc),
        .wb_reg_write (wb_reg_write_sig),
        .wb_rd        (wb_rd_sig),
        .wb_wd        (wb_data_sig),
        .rs1_data     (id_rs1_data),
        .rs2_data     (id_rs2_data),
        .imm          (id_imm),
        .rs1_addr     (id_rs1_addr),
        .rs2_addr     (id_rs2_addr),
        .rd_addr      (id_rd_addr),
        .funct3       (id_funct3),
        .funct7b5     (id_funct7b5),
        .reg_write    (id_reg_write),
        .alu_src_b    (id_alu_src_b),
        .alu_src_a    (id_alu_src_a),
        .mem_read     (id_mem_read),
        .mem_write    (id_mem_write),
        .mem_to_reg   (id_mem_to_reg),
        .branch       (id_branch),
        .jump         (id_jump),
        .jalr         (id_jalr),
        .alu_op       (id_alu_op)
    );

    // ====================================================================== //
    //  ID/EX pipeline register
    // ====================================================================== //
    wire [31:0] idex_rs1_data, idex_rs2_data, idex_imm, idex_pc, idex_pc_plus4;
    wire [4:0]  idex_rs1_addr, idex_rs2_addr, idex_rd_addr;
    wire [2:0]  idex_funct3;
    wire        idex_funct7b5;
    wire        idex_reg_write, idex_alu_src_b, idex_alu_src_a;
    wire        idex_mem_read, idex_mem_write;
    wire [1:0]  idex_mem_to_reg;
    wire        idex_branch, idex_jump, idex_jalr;
    wire [1:0]  idex_alu_op;

    id_ex_reg id_ex (
        .clk           (clk),
        .reset         (reset),
        .flush         (id_ex_flush),
        .rs1_data_in   (id_rs1_data),
        .rs2_data_in   (id_rs2_data),
        .imm_in        (id_imm),
        .pc_in         (ifid_pc),
        .pc_plus4_in   (ifid_pc + 32'd4),
        .rs1_addr_in   (id_rs1_addr),
        .rs2_addr_in   (id_rs2_addr),
        .rd_addr_in    (id_rd_addr),
        .funct3_in     (id_funct3),
        .funct7b5_in   (id_funct7b5),
        .reg_write_in  (id_reg_write),
        .alu_src_b_in  (id_alu_src_b),
        .alu_src_a_in  (id_alu_src_a),
        .mem_read_in   (id_mem_read),
        .mem_write_in  (id_mem_write),
        .mem_to_reg_in (id_mem_to_reg),
        .branch_in     (id_branch),
        .jump_in       (id_jump),
        .jalr_in       (id_jalr),
        .alu_op_in     (id_alu_op),

        .rs1_data_out  (idex_rs1_data),
        .rs2_data_out  (idex_rs2_data),
        .imm_out       (idex_imm),
        .pc_out        (idex_pc),
        .pc_plus4_out  (idex_pc_plus4),
        .rs1_addr_out  (idex_rs1_addr),
        .rs2_addr_out  (idex_rs2_addr),
        .rd_addr_out   (idex_rd_addr),
        .funct3_out    (idex_funct3),
        .funct7b5_out  (idex_funct7b5),
        .reg_write_out (idex_reg_write),
        .alu_src_b_out (idex_alu_src_b),
        .alu_src_a_out (idex_alu_src_a),
        .mem_read_out  (idex_mem_read),
        .mem_write_out (idex_mem_write),
        .mem_to_reg_out(idex_mem_to_reg),
        .branch_out    (idex_branch),
        .jump_out      (idex_jump),
        .jalr_out      (idex_jalr),
        .alu_op_out    (idex_alu_op)
    );

    // ====================================================================== //
    //  EX stage
    // ====================================================================== //
    wire [31:0] ex_alu_result, ex_rs2_fwd_data;
    wire [4:0]  ex_rd_addr;

    // EX/MEM ALU result for forwarding (declared at EX/MEM register)
    wire [31:0] exmem_alu_result;

    ex_stage ex_inst (
        .rs1_data         (idex_rs1_data),
        .rs2_data         (idex_rs2_data),
        .imm              (idex_imm),
        .pc               (idex_pc),
        .rd_addr          (idex_rd_addr),
        .funct3           (idex_funct3),
        .funct7b5         (idex_funct7b5),
        .alu_src_a        (idex_alu_src_a),
        .alu_src_b        (idex_alu_src_b),
        .branch           (idex_branch),
        .jump             (idex_jump),
        .jalr             (idex_jalr),
        .alu_op           (idex_alu_op),
        .forwardA         (forwardA),
        .forwardB         (forwardB),
        .ex_mem_alu_result(exmem_alu_result),
        .wb_data          (wb_data_sig),
        .alu_result       (ex_alu_result),
        .rs2_fwd_data     (ex_rs2_fwd_data),
        .rd_addr_out      (ex_rd_addr),
        .branch_taken     (branch_taken),
        .branch_target    (branch_target)
    );

    // ====================================================================== //
    //  EX/MEM pipeline register
    // ====================================================================== //
    wire [31:0] exmem_rs2_data, exmem_pc_plus4;
    wire [4:0]  exmem_rd_addr;
    wire [2:0]  exmem_funct3;
    wire        exmem_reg_write, exmem_mem_read, exmem_mem_write;
    wire [1:0]  exmem_mem_to_reg;

    ex_mem_reg ex_mem (
        .clk           (clk),
        .reset         (reset),
        .alu_result_in (ex_alu_result),
        .rs2_data_in   (ex_rs2_fwd_data),
        .rd_addr_in    (ex_rd_addr),
        .pc_plus4_in   (idex_pc_plus4),
        .funct3_in     (idex_funct3),
        .reg_write_in  (idex_reg_write),
        .mem_read_in   (idex_mem_read),
        .mem_write_in  (idex_mem_write),
        .mem_to_reg_in (idex_mem_to_reg),

        .alu_result_out(exmem_alu_result),
        .rs2_data_out  (exmem_rs2_data),
        .rd_addr_out   (exmem_rd_addr),
        .pc_plus4_out  (exmem_pc_plus4),
        .funct3_out    (exmem_funct3),
        .reg_write_out (exmem_reg_write),
        .mem_read_out  (exmem_mem_read),
        .mem_write_out (exmem_mem_write),
        .mem_to_reg_out(exmem_mem_to_reg)
    );

    // ====================================================================== //
    //  MEM stage
    // ====================================================================== //
    wire [31:0] mem_alu_result_out, mem_data_out, mem_pc_plus4_out;
    wire [4:0]  mem_rd_addr_out;

    mem_stage mem_inst (
        .clk          (clk),
        .alu_result   (exmem_alu_result),
        .rs2_data     (exmem_rs2_data),
        .rd_addr      (exmem_rd_addr),
        .pc_plus4     (exmem_pc_plus4),
        .funct3       (exmem_funct3),
        .mem_read     (exmem_mem_read),
        .mem_write    (exmem_mem_write),
        .alu_result_out(mem_alu_result_out),
        .mem_data     (mem_data_out),
        .rd_addr_out  (mem_rd_addr_out),
        .pc_plus4_out (mem_pc_plus4_out)
    );

    // ====================================================================== //
    //  MEM/WB pipeline register
    // ====================================================================== //
    wire [31:0] memwb_alu_result, memwb_mem_data, memwb_pc_plus4;
    wire [4:0]  memwb_rd_addr;
    wire        memwb_reg_write;
    wire [1:0]  memwb_mem_to_reg;

    mem_wb_reg mem_wb (
        .clk           (clk),
        .reset         (reset),
        .alu_result_in (mem_alu_result_out),
        .mem_data_in   (mem_data_out),
        .rd_addr_in    (mem_rd_addr_out),
        .pc_plus4_in   (mem_pc_plus4_out),
        .reg_write_in  (exmem_reg_write),
        .mem_to_reg_in (exmem_mem_to_reg),

        .alu_result_out(memwb_alu_result),
        .mem_data_out  (memwb_mem_data),
        .rd_addr_out   (memwb_rd_addr),
        .pc_plus4_out  (memwb_pc_plus4),
        .reg_write_out (memwb_reg_write),
        .mem_to_reg_out(memwb_mem_to_reg)
    );

    // ====================================================================== //
    //  WB stage
    // ====================================================================== //
    wb_stage wb_inst (
        .alu_result  (memwb_alu_result),
        .mem_data    (memwb_mem_data),
        .pc_plus4    (memwb_pc_plus4),
        .mem_to_reg  (memwb_mem_to_reg),
        .reg_write   (memwb_reg_write),
        .rd_addr     (memwb_rd_addr),
        .wb_data     (wb_data_sig),
        .wb_reg_write(wb_reg_write_sig),
        .wb_rd       (wb_rd_sig)
    );

    // ====================================================================== //
    //  Hazard unit
    // ====================================================================== //
    hazard_unit hazard_inst (
        .id_ex_mem_read   (idex_mem_read),
        .id_ex_rd         (idex_rd_addr),
        .if_id_rs1        (ifid_instr[19:15]),
        .if_id_rs2        (ifid_instr[24:20]),
        .id_ex_rs1        (idex_rs1_addr),
        .id_ex_rs2        (idex_rs2_addr),
        .ex_mem_reg_write (exmem_reg_write),
        .ex_mem_rd        (exmem_rd_addr),
        .mem_wb_reg_write (memwb_reg_write),
        .mem_wb_rd        (memwb_rd_addr),
        .branch_taken     (branch_taken),
        .pc_write_en      (pc_write_en),
        .if_id_write_en   (if_id_write_en),
        .id_ex_flush      (id_ex_flush),
        .if_id_flush      (if_id_flush),
        .forwardA         (forwardA),
        .forwardB         (forwardB)
    );

endmodule
