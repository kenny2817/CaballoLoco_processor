# CaballoLoco_processor

The fastest processor whenever Will Smith is in the backstage.

This repository contains the System Verilog code for the CaballoLoco processor. The project is organized into several modules, each with its corresponding testbench. The objective of this project is to optimize the processor more and more to understand every optimization step.

objectives:

- [DONE] single cycle processor - CaBalloSano
- [DONE] pipelined processor - CaBalloLoco
- [ ] cache
- [ ] TLB
- [ ] memory
- [ ] memory arbiter
- [ ] speculation
- [ ] multiple issue

## Folder Structure

- `modules/`: This directory contains the source files for all the individual modules of the processor combined with the testbenches.
- `pkgs/`: This directory contains the source files for all the packages used in the project.
- `docs/`: This directory contains documentation related to the project, such as design specifications, architectural diagrams, or any other relevant information. Here you will find shemas of the various implementations.

## Contents

### Modules

- [Arithmetic Logic Unit](modules/alu.sv)
- [Program Counter Incrementer](modules/pc_incrementer.sv)
- [Demultiplexer](modules/demux.sv)
- [Multiplexer](modules/mux.sv)
- [Register](modules/register.sv)
- [Register Bank](modules/register_bank.sv)
- [Comparator](modules/comparator.sv)
- [Opcode Decoder](modules/opcode_decoder.sv)
- [Exception Unit](./modules/exception_unit.sv)
- [Forward Unit](modules/forward_unit.sv)
- [Main Logic - single cycle (CaBalloSano)](modules/caballosano_single_cycle.sv)
- [Main Logic - pipelined (CaBalloLoco)](modules/caballoloco_pipelined.sv)

### Packages

- Arithmetic logic unit operands
- Comparator operand
- CPU operands - opcodes

## TODO

- [ ] shift left - shl
- [ ] shift right - shr
- [ ] cache
- [ ] TLB
- [ ] memory

## Future work

- [ ] speculation branch
- [ ] speculation memory
- [ ] multi-level cache
- [ ] multiple issue
- [ ] memory arbiter
