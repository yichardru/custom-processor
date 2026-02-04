# Simplified 5-Stage RISC-V Pipelined Processor 
This is my iteration of a pipelined processor designed to run the RISC-V RV32I instruction set with hazard detection and data forwarding.

## Overview
This design is a 5-stage pipelined RISC-V processor running the 32-bit (RV32I) instruction set without extensions (namely, multiply/division). The five stages follow the classical pipeline structure (IF, ID, EX, MEM, WB), which allows for up to five instructions to run concurrently. The processor uses a 32-bit datapath and reg file. 
For now, this processor will only access memory through load/store, and assumes the memory to be divided into instruction and data segments. There are no branch predictions or CSR (no interrupts) since I've omitted these for simplicity.

### Memory
As mentioned, this processor assumes instructions and data to be separate to avoid hazards between IF and MEM. All memory operations are 32-bit aligned and address space is byte-addressable.

### Register File
The RF has 32 32-bit registers (x0-x31) with two read ports and one write port. I've designed it to write to reg file in the first half of the clock cycle via WB, and read in the second half of the cycle via ID. This design is to support data forwarding by allowing the decode stage to read from reg file right after writeback. 

## Pipeline Stages
### Instruction Fetch (IF)
During IF, the processor fetches from instruction memory (located somewhere) noted by PC, then the PC is incremented by 4. This stage outputs the 32-bit fetched instruction into the IF/ID pipeline register for the next stage.

### Instruction Decode (ID)
During ID, the 32-bit instruction is read from the pipeline register and decoded into respective fields. This is followed by generating the control signals and any necessary values (imm, reg, etc) to be stored in the ID/EX pipeline register. ID also inserts a NOP bubble if a hazard is detected.

### Execute (EX)
I assume if you are reading this, you already have a pretty good understanding of how ALUs work, so I will leave a good chunk of this part out.
I do want to mention branch behavior in this processor. Unlike some, branching is done in EX instead of ID and the branch target will either be the address computed or PC + 4. Due to the nature of pipelined processors, there will be at least one instruction that is fetched/decoded without knowing if we branched.

### Memory (MEM)
I'm too lazy to handle misalignment, so for now this implementation will only assume aligned accesses. 
The outputs of this stage will include a flag indicating if writeback is needed or not.

### Writeback (WB)
WB will only write ALU instructions or Load instructions.  

## Hazard Handling
Naturally, there are 2 hazards present in any pipeline architectures - structural and data. The complex one being the latter.
As this processor is in-order, the only real hazard is Read After Write (RAW). I will handle it by providing two data bypasses. 
* EX to EX: If the older instruction (call it i1) has an ALU data that the younger instruction (i2) needs, I will forward it from the EX/MEM register. In hardware, this means if the ALU detects i2's R1/R2 matches with i1's DR, it will select the forwarded ALU value (from EX/MEM) instead of RF output.
* MEM to EX: Essentially the same thing but 2 cycles ahead. I will provide a bypass from MEM/WB register into EX. Note this will only work with 1-cycle memory accesses and will probably break if memory accesses take longer.

Additionally, I also have interlocks between stages that will create a bubble/NOP if we are stalled. 

## Control Hazards (Branching)
Since we don't implement branch prediction, stages will sometimes be flushed. To do so, I will simply have a control logic that turns incorrectly fetched instructions into bubbles/NOPs.


thanks for coming to my ted talk

## References
_Patterson & Hennessy, Computer Organization and Design_ – RISC-V Edition

RISC-V ISA Specification, Volume 1 https://docs.riscv.org/reference/isa/unpriv/rv32.html
