`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: wb_stage
// Description: Write-back stage.  Selects the value to be written back to
//              the register file based on the mem_to_reg control signal.
//
// mem_to_reg:
//   2'b00  ALU result  (R-type, I-type ALU, LUI, AUIPC)
//   2'b01  Memory data (loads)
//   2'b10  PC + 4      (JAL / JALR – return address)
//////////////////////////////////////////////////////////////////////////////////

module wb_stage (
    // From MEM/WB pipeline register
    input  [31:0] alu_result,
    input  [31:0] mem_data,
    input  [31:0] pc_plus4,
    input  [1:0]  mem_to_reg,
    input         reg_write,
    input  [4:0]  rd_addr,

    // To register file and forwarding
    output [31:0] wb_data,
    output        wb_reg_write,
    output [4:0]  wb_rd
);

    assign wb_data =
        (mem_to_reg == 2'b01) ? mem_data  :
        (mem_to_reg == 2'b10) ? pc_plus4  :
                                alu_result;

    assign wb_reg_write = reg_write;
    assign wb_rd        = rd_addr;

endmodule
