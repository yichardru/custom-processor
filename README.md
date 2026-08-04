# Simplified 5-Stage RISC-V Pipelined Processor 
This is my iteration of a pipelined processor designed to run the RISC-V RV32I instruction set with hazard detection and data forwarding.

## Overview
This design is a 5-stage pipelined RISC-V processor running the 32-bit (RV32I) instruction set without extensions (namely, multiply/division). The five stages follow the classical pipeline structure (IF, ID, EX, MEM, WB), which allows for up to five instructions to run concurrently. The processor uses a 32-bit datapath and reg file. 
For now, this processor will only access memory through load/store, and assumes the memory to be divided into instruction and data segments. There are no branch predictions or CSR (no interrupts) since I've omitted these for simplicity.

### Memory
As mentioned, this processor assumes instructions and data to be separate to avoid hazards between IF and MEM. All memory operations are 32-bit aligned and address space is byte-addressable.

### Register File
The RF has 32 32-bit registers (x0-x31) with two read ports and one write port. Writes happen on the rising edge (WB), and reads are combinational (ID). To let ID observe a same-cycle WB write, the read ports have a write-first bypass: if the address being written this cycle matches the address being read, the incoming write data is forwarded directly instead of the stale array contents. This is what closes the gap for RAW hazards that are too far apart (3+ instructions) for the EX-stage forwarding muxes below to catch.

## Pipeline Stages
### Instruction Fetch (IF)
During IF, the processor fetches from instruction memory (located somewhere) noted by PC, then the PC is incremented by 4. This stage outputs the 32-bit fetched instruction into the IF/ID pipeline register for the next stage.

### Instruction Decode (ID)
During ID, the 32-bit instruction is read from the pipeline register and decoded into respective fields. This is followed by generating the control signals and any necessary values (imm, reg, etc) to be stored in the ID/EX pipeline register. ID also inserts a NOP bubble if a hazard is detected.

### Execute (EX)
I assume if you are reading this, you already have a pretty good understanding of how ALUs work, so I will leave a good chunk of this part out.
I do want to mention branch behavior in this processor. Unlike some, branching is done in EX instead of ID and the branch target will either be the address computed or PC + 4. Because resolution happens in EX, by the time a branch/jump is evaluated two more instructions have already been fetched on the not-taken path — so a taken branch or jump costs a 2-cycle flush (IF/ID and ID/EX both get turned into bubbles).

### Memory (MEM)
I'm too lazy to handle misalignment, so for now this implementation will only assume aligned accesses. 
The outputs of this stage will include a flag indicating if writeback is needed or not.

### Writeback (WB)
WB writes back one of three things, selected per-instruction: the ALU result (R-type/I-type ALU/LUI/AUIPC), loaded memory data (loads), or PC+4 (JAL/JALR, for the return address).

## Hazard Handling
Naturally, there are 2 hazards present in any pipeline architectures - control and data. The complex one being the latter.
As this processor is in-order, the only real hazard is Read After Write (RAW). I handle it with three data bypasses, two of them explicit forwarding muxes and one built into the register file:
* EX to EX: If the older instruction (call it i1) has an ALU data that the younger instruction (i2) needs, I will forward it from the EX/MEM register. In hardware, this means if the ALU detects i2's R1/R2 matches with i1's DR, it will select the forwarded ALU value (from EX/MEM) instead of RF output. This only forwards when i1's writeback value actually *is* the ALU result — if i1 is a load or JAL/JALR, EX/MEM only holds an address or a don't-care value, so this path is gated off for those cases (the load-use stall and the branch flush's pipeline depth respectively keep those producers from ever needing it, but the gating makes that an enforced invariant rather than a timing coincidence).
* MEM to EX: Essentially the same thing but 2 cycles ahead. I will provide a bypass from MEM/WB register into EX. Note this will only work with 1-cycle memory accesses and will probably break if memory accesses take longer.
* WB to ID (register file write-first bypass): for RAW hazards spaced 3+ instructions apart, the dependent instruction reads its operand straight out of ID by the time the producer reaches WB — no EX-stage forwarding mux is involved. See the Register File section above.

Additionally, I also have interlocks between stages that will create a bubble/NOP if we are stalled. Only opcodes that actually source rs1/rs2 (R-type, I-type ALU, loads, stores, branches, JALR) are checked for the load-use hazard — LUI/AUIPC/JAL reuse those instruction bits as immediate, not register fields, so they're excluded.

## Control Hazards (Branching)
Since we don't implement branch prediction, stages will sometimes be flushed. To do so, I will simply have a control logic that turns incorrectly fetched instructions into bubbles/NOPs.


thanks for coming to my ted talk

## Known Limitations
* No bounds checking on memory addresses: instruction memory is 256 words (1KB) and data memory is 1KB, both accessed by truncating the low address bits. An access outside that range silently aliases back into the array instead of faulting.
* JALR/branch targets aren't checked for 2-byte alignment beyond clearing bit 0 of JALR's target; a misaligned target is silently truncated by the word-aligned fetch rather than trapped (there's no CSR/exception support at all in this design, so this is consistent with that scope, just worth calling out explicitly).
* A load immediately followed by a store that consumes the loaded value still takes the 1-cycle load-use stall, even though only the store's address (not its data) needs the value in EX. A MEM-stage store-data bypass could remove this stall but isn't implemented.
* JAL/JALR always pay the full 2-cycle taken-branch flush even though JAL's target is computable in ID (no register read required). Resolving JAL earlier is a possible future optimization.

## References
_Patterson & Hennessy, Computer Organization and Design_ – RISC-V Edition

RISC-V ISA Specification, Volume 1 https://docs.riscv.org/reference/isa/unpriv/rv32.html
