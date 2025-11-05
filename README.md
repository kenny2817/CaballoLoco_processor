# CaballoLoco Processor

The fastest processor whenever Will Smith is in the backstage.

This repository contains the System Verilog code for the CaballoLoco processor. The project is organized into several modules, each with its corresponding testbench. The objective of this project is to optimize the processor more and more to understand every optimization step.

## Objectives

- [x] **Single Cycle Processor:** CaBalloSano
- [x] **Pipelined Processor:** CaBalloLoco
- [ ] **Cache:** Implement a cache memory.
- [ ] **TLB:** Implement a Translation Lookaside Buffer.
- [ ] **Memory:** Implement a memory module.
- [ ] **Memory Arbiter:** Implement a memory arbiter.
- [ ] **Speculation:** Implement branch and memory speculation.
- [ ] **Multiple Issue:** Implement multiple issue.

## Folder Structure

Each implementation has its own folder with the following structure:

- `mod/`: Contains the source files for all the individual modules of the processor combined with the testbenches.
- `pkg/`: Contains the source files for all the packages used in the project.
- `tc/`: Contains the source files for all the testbenches.
- `doc/`: Contains documentation related to the project, such as design specifications, architectural diagrams, or any other relevant information. Here you will find schemas of the various implementations.
- `Makefile`: Icarus verilog Makefile.

## Contents

### Modules

- [Arithmetic Logic Unit](modules/arithmetic_logic_unit.sv)
- [Comparator](modules/comparator.sv)
- [Demultiplexer](modules/demultiplexer.sv)
- [Forwarding Unit](modules/forwarding.sv)
- [Hazard Unit](modules/hazard.sv)
- [Multiplexer](modules/multiplexer.sv)
- [Opcode Decoder](modules/opcode_decoder_32.sv)
- [Pipes](modules/pipes.sv)
- [Program Counter Incrementer](modules/program_counter_incrementer.sv)
- [Register](modules/register_multiple.sv)
- [Register Bank](modules/register_bank.sv)
- [Main Logic - Single Cycle (CaBalloSano)](modules/caballosano_single_cycle.sv)
- [Main Logic - Pipelined (CaBalloLoco)](modules/caballoloco_pipelined.sv)

### Packages

- [ALU Package](pkgs/alu_pkg.sv)
- [Comparator Package](pkgs/cmp_pkg.sv)
- [Opcodes Package](pkgs/opcodes_pkg.sv)

## TODO

- [ ] **Shift Left (shl):** Implement the shift left operation.
- [ ] **Shift Right (shr):** Implement the shift right operation.
- [ ] **Cache:** Implement the cache memory.
- [ ] **Store Buffer:** Implement the store buffer.
- [ ] **TLB:** Implement the Translation Lookaside Buffer.
- [ ] **Memory:** Implement the main memory.

## Future Work

- [ ] **Branch Speculation:** Implement branch speculation to improve performance.
- [ ] **Memory Speculation:** Implement memory speculation.
- [ ] **Multi-level Cache:** Implement a multi-level cache hierarchy.
- [ ] **Multiple Issue:** Implement a multiple issue pipeline.
- [ ] **Memory Arbiter:** Implement a memory arbiter for managing memory access.
