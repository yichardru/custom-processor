`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: hazard_unit
// Description: Centralized hazard detection and data-forwarding control.
//
// --- Load-use stall ---
//   Triggered when the instruction in EX is a load (id_ex_mem_read=1) and
//   its destination register matches a source register of the instruction
//   currently in ID.
//   Action: stall PC and IF/ID for one cycle; flush ID/EX to insert a bubble.
//
// --- Data forwarding ---
//   forwardA / forwardB select the correct ALU operand for the EX stage:
//     2'b00  reg-file value (from ID/EX)
//     2'b01  MEM/WB write-back data  (2 instructions ago)
//     2'b10  EX/MEM ALU result       (1 instruction ago)
//   EX hazard takes priority over MEM hazard.
//
// --- Branch / jump flush ---
//   When branch_taken is asserted by the EX stage, both IF/ID and ID/EX must
//   be flushed to discard the two incorrectly fetched instructions.
//   The PC stall is overridden so the PC can redirect to branch_target.
//////////////////////////////////////////////////////////////////////////////////

module hazard_unit (
    // Load-use detection inputs
    input        id_ex_mem_read,
    input  [4:0] id_ex_rd,
    input  [4:0] if_id_rs1,
    input  [4:0] if_id_rs2,

    // Forwarding inputs (EX stage)
    input  [4:0] id_ex_rs1,
    input  [4:0] id_ex_rs2,
    input        ex_mem_reg_write,
    input  [4:0] ex_mem_rd,
    input        mem_wb_reg_write,
    input  [4:0] mem_wb_rd,

    // Branch taken from EX stage
    input        branch_taken,

    // Stall / flush control outputs
    output reg        pc_write_en,    // 1 = advance PC normally
    output reg        if_id_write_en, // 1 = advance IF/ID normally
    output reg        id_ex_flush,    // 1 = insert NOP into ID/EX
    output reg        if_id_flush,    // 1 = insert NOP into IF/ID

    // Forwarding mux selects
    output reg [1:0]  forwardA,
    output reg [1:0]  forwardB
);

    // Load-use hazard detection
    wire load_use_hazard =
        id_ex_mem_read &&
        ( (id_ex_rd == if_id_rs1 && if_id_rs1 != 5'b0) ||
          (id_ex_rd == if_id_rs2 && if_id_rs2 != 5'b0) );

    // Stall / flush control
    always @(*) begin
        if (branch_taken) begin
            // Flush the two instructions fetched after the branch
            pc_write_en    = 1'b1;  // let PC redirect to branch_target
            if_id_write_en = 1'b1;  // IF/ID will be flushed via if_id_flush
            if_id_flush    = 1'b1;
            id_ex_flush    = 1'b1;
        end else if (load_use_hazard) begin
            // Stall IF and ID for one cycle; insert NOP into EX
            pc_write_en    = 1'b0;
            if_id_write_en = 1'b0;
            if_id_flush    = 1'b0;
            id_ex_flush    = 1'b1;
        end else begin
            // Normal operation
            pc_write_en    = 1'b1;
            if_id_write_en = 1'b1;
            if_id_flush    = 1'b0;
            id_ex_flush    = 1'b0;
        end
    end

    // EX-stage forwarding for operand A (rs1)
    always @(*) begin
        if (ex_mem_reg_write && ex_mem_rd != 5'b0 &&
            ex_mem_rd == id_ex_rs1)
            forwardA = 2'b10;  // forward from EX/MEM
        else if (mem_wb_reg_write && mem_wb_rd != 5'b0 &&
                 mem_wb_rd == id_ex_rs1)
            forwardA = 2'b01;  // forward from MEM/WB
        else
            forwardA = 2'b00;  // use reg-file value
    end

    // EX-stage forwarding for operand B (rs2)
    always @(*) begin
        if (ex_mem_reg_write && ex_mem_rd != 5'b0 &&
            ex_mem_rd == id_ex_rs2)
            forwardB = 2'b10;  // forward from EX/MEM
        else if (mem_wb_reg_write && mem_wb_rd != 5'b0 &&
                 mem_wb_rd == id_ex_rs2)
            forwardB = 2'b01;  // forward from MEM/WB
        else
            forwardB = 2'b00;  // use reg-file value
    end

endmodule
