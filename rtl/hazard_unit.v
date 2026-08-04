`timescale 1ns / 1ps

module hazard_unit (
    // Load-use hazard detection
    input        id_ex_mem_read,
    input  [4:0] id_ex_rd,
    input  [4:0] if_id_rs1,
    input  [4:0] if_id_rs2,
    input  [6:0] if_id_opcode,   // instruction currently in ID, to know which fields are real regs
    // Branch/jump flush
    input        branch_taken,
    // Outputs
    output       pc_write_en,     // 0 = stall PC
    output       if_id_write_en,  // 0 = stall IF/ID
    output       id_ex_flush,     // 1 = insert bubble in ID/EX
    output       if_id_flush      // 1 = flush IF/ID on branch
);

    // Instructions whose bits[19:15]/bits[24:20] are actually rs1/rs2 (as
    // opposed to LUI/AUIPC/JAL, which reuse those bits as part of the
    // immediate and must not be treated as register dependencies)
    wire uses_rs1 = (if_id_opcode == 7'b0110011) || // R-type
                    (if_id_opcode == 7'b0010011) || // I-type ALU
                    (if_id_opcode == 7'b0000011) || // Load
                    (if_id_opcode == 7'b0100011) || // Store
                    (if_id_opcode == 7'b1100011) || // Branch
                    (if_id_opcode == 7'b1100111);   // JALR

    wire uses_rs2 = (if_id_opcode == 7'b0110011) || // R-type
                    (if_id_opcode == 7'b0100011) || // Store
                    (if_id_opcode == 7'b1100011);   // Branch

    // Load-use hazard: stall when a load in EX is followed by a dependent instruction in ID
    wire load_use_hazard = id_ex_mem_read && (id_ex_rd != 5'd0) &&
                           ((uses_rs1 && (id_ex_rd == if_id_rs1)) ||
                            (uses_rs2 && (id_ex_rd == if_id_rs2)));

    // Stall signals (active-low: 0 = stall)
    assign pc_write_en    = ~load_use_hazard;
    assign if_id_write_en = ~load_use_hazard;

    // Flush signals
    assign if_id_flush = branch_taken;
    assign id_ex_flush = branch_taken | load_use_hazard;

endmodule
