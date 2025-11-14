# CaballoLoco Processor

The fastest processor whenever Will Smith is in the backstage.

This repository contains the System Verilog code for the CaballoLoco processor. The project is organized into several modules, each with its corresponding testbench. The objective of this project is to optimize the processor more and more to understand every optimization step.

## Main Implementations

each of these has a dedicated folder

### Single Cycle Processor: CaBalloSano - CBS

| Name <img width="200" height="1" alt=""> |                   Module                   |            Testbench             |
| ---------------------------------------- | :----------------------------------------: | :------------------------------: |
| Main Logic                               | [mod](CBS/mod/caballosano_single_cycle.sv) |      [tb](CBS/tb/cbs_tb.sv)      |
| Arithmetic Logic Unit                    |  [mod](CBS/mod/arithmetic_logic_unit.sv)   |      [tb](CBS/tb/alu_tb.sv)      |
| Comparator                               |        [mod](CBS/mod/comparator.sv)        |      [tb](CBS/tb/cmp_tb.sv)      |
| Opcode Decoder                           |    [mod](CBS/mod/opcode_decoder_32.sv)     |    [tb](CBS/tb/opd_32_tb.sv)     |
| Register Bank                            |      [mod](CBS/mod/register_bank.sv)       |   [tb](CBS/tb/reg_bank_tb.sv)    |
| Register Mono                            |      [mod](CBS/mod/register_mono.sv)       |   [tb](CBS/tb/reg_mono_tb.sv)    |
| Register Bank Mono                       |    [mod](CBS/mod/register_bank_mono.sv)    | [tb](CBS/tb/reg_bank_mono_tb.sv) |

### Pipelined Processor: CaBalloLoco - CBL

| Name <img width="200" height="1" alt=""> |                 Module                  |            Testbench             |
| ---------------------------------------- | :-------------------------------------: | :------------------------------: |
| Main Logic                               | [mod](CBL/mod/caballoloco_pipelined.sv) |      [tb](CBL/tb/cbl_tb.sv)      |
| Arithmetic Logic Unit                    | [mod](CBL/mod/arithmetic_logic_unit.sv) |      [tb](CBS/tb/cbs_tb.sv)      |
| Comparator                               |      [mod](CBL/mod/comparator.sv)       |      [tb](CBS/tb/cmp_tb.sv)      |
| Forwarding Unit                          |      [mod](CBL/mod/forwarding.sv)       |      [tb](CBL/tb/fwd_tb.sv)      |
| Hazard Unit                              |        [mod](CBL/mod/hazard.sv)         |      [tb](CBL/tb/haz_tb.sv)      |
| Opcode Decoder                           |   [mod](CBL/mod/opcode_decoder_32.sv)   |    [tb](CBS/tb/opd_32_tb.sv)     |
| Pipes                                    |         [mod](CBL/mod/pipes.sv)         |      [tb](CBL/pipes_tb.sv)       |
| Register Bank                            |     [mod](CBL/mod/register_bank.sv)     |   [tb](CBL/tb/reg_bank_tb.sv)    |
| Register Mono                            |     [mod](CBL/mod/register_mono.sv)     |   [tb](CBL/tb/reg_mono_tb.sv)    |
| Register Bank Mono                       |  [mod](CBL/mod/register_bank_mono.sv)   | [tb](CBL/tb/reg_bank_mono_tb.sv) |

### Pipelined Processor with memory: CaBalloDesquiciado - CBD

| Name <img width="200" height="1" alt=""> |                     Module                     |       Testbench        |
| ---------------------------------------- | :--------------------------------------------: | :--------------------: |
| Main Logic                               | [mod](CBD/mod/caballodesquiciado_pipelined.sv) |           /            |
| Arbiter                                  |           [mod](CBD/mod/arbiter.sv)            | [tb](CBD/tb/arb_tb.sv) |
| Data Cache                               |          [mod](CBD/mod/data_cache.sv)          | [tb](CBD/tb/dca_tb.sv) |
| Data Memory                              |         [mod](CBD/mod/data_memory.sv)          |           /            |
| Instruction Cache                        |      [mod](CBD/mod/instruction_cache.sv)       | [tb](CBD/tb/ica_tb.sv) |
| Instruction Memory                       |      [mod](CBD/mod/instruction_memory.sv)      |           /            |
| Store Buffer                             |         [mod](CBD/mod/store_buffer.sv)         | [tb](CBD/tb/stb_tb.sv) |
| Translation Lookaside Buffer             |             [mod](CBD/mod/tlb.sv)              | [tb](CBD/tb/tlb_tb.sv) |

#### TODO

- [x] **Cache:** Implement a cache memory.
- [x] **TLB:** Implement a Translation Lookaside Buffer.
- [ ] **Memory:** Implement a memory module.
- [x] **Memory Arbiter:** Implement a memory arbiter.
- [ ] **Speculation:** Implement branch and memory speculation.
- [ ] **Multiple Issue:** Implement multiple issue.

## Folder Structure

Each implementation has its own folder with the following structure:

- `mod/`: Contains the source files for all the individual modules of the processor combined with the testbenches.
- `pkg/`: Contains the source files for all the packages used in the project.
- `tc/`: Contains the source files for all the testbenches.
- `doc/`: Contains documentation related to the project, such as design specifications, architectural diagrams, or any other relevant information. Here you will find schemas of the various implementations.
- `Makefile`: Icarus verilog Makefile.

## TODO

- [ ] **Shift Left (shl):** Implement the shift left operation.
- [ ] **Shift Right (shr):** Implement the shift right operation.
- [ ] **Memory:** Implement the main memory.

## Future Work

- [ ] **Branch Speculation:** Implement branch speculation to improve performance.
- [ ] **Memory Speculation:** Implement memory speculation.
- [ ] **Multi-level Cache:** Implement a multi-level cache hierarchy.
- [ ] **Multiple Issue:** Implement a multiple issue pipeline.
