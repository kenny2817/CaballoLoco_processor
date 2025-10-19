IFLAGS = -g2012 -Wall
MODULES_DIR = modules
PKG_DIR = pkgs
PKGS = $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv
TARGETS = mux demux cmp reg_multi alu reg_bank pci opd_32 cbs reg_mono reg_bank_mono cbl haz fwd pipes

define IVERILOG_COMPILE
	@iverilog $(IFLAGS) -s $@_tb -o $@ $^ || (echo "failed - $@"; exit 1)
	@echo "success - $@"
endef

.PHONY: all $(TARGETS) clean

icarus: $(TARGETS)

mux: $(MODULES_DIR)/multiplexer.sv
	${IVERILOG_COMPILE}

demux: $(MODULES_DIR)/demultiplexer.sv
	${IVERILOG_COMPILE}

reg_multi: $(MODULES_DIR)/register_multiple.sv
	${IVERILOG_COMPILE}

reg_bank: $(MODULES_DIR)/register_bank.sv
	${IVERILOG_COMPILE}

reg_bank_mono: $(MODULES_DIR)/register_bank_mono.sv
	${IVERILOG_COMPILE}

cmp: $(PKG_DIR)/cmp_pkg.sv $(MODULES_DIR)/comparator.sv
	${IVERILOG_COMPILE}

alu: $(PKG_DIR)/alu_pkg.sv $(MODULES_DIR)/arithmetic_logic_unit.sv
	${IVERILOG_COMPILE}

pci: $(MODULES_DIR)/program_counter_incrementer.sv
	${IVERILOG_COMPILE}

opd_32: ${PKGS}  $(MODULES_DIR)/opcode_decoder_32.sv
	${IVERILOG_COMPILE}

cbs: ${PKGS} $(MODULES_DIR)/caballosano_single_cycle.sv $(MODULES_DIR)/register_mono.sv $(MODULES_DIR)/program_counter_incrementer.sv $(MODULES_DIR)/opcode_decoder_32.sv $(MODULES_DIR)/register_bank.sv $(MODULES_DIR)/register_bank_mono.sv $(MODULES_DIR)/arithmetic_logic_unit.sv $(MODULES_DIR)/comparator.sv
	${IVERILOG_COMPILE}

cbl: ${PKGS} $(MODULES_DIR)/caballoloco_pipelined.sv $(MODULES_DIR)/forwarding.sv $(MODULES_DIR)/pipes.sv $(MODULES_DIR)/hazard.sv $(MODULES_DIR)/register_mono.sv $(MODULES_DIR)/multiplexer.sv $(MODULES_DIR)/opcode_decoder_32.sv $(MODULES_DIR)/register_bank.sv $(MODULES_DIR)/register_bank_mono.sv $(MODULES_DIR)/arithmetic_logic_unit.sv $(MODULES_DIR)/comparator.sv
	${IVERILOG_COMPILE}

reg_mono: $(MODULES_DIR)/register_mono.sv
	${IVERILOG_COMPILE}

haz: ${PKGS}  $(MODULES_DIR)/hazard.sv
	${IVERILOG_COMPILE}

fwd: ${PKGS}  $(MODULES_DIR)/forwarding.sv
	${IVERILOG_COMPILE}

pipes: ${PKGS}  $(MODULES_DIR)/pipes.sv
	${IVERILOG_COMPILE}

S: ${PKGS}  $(MODULES_DIR)/S.sv
	${IVERILOG_COMPILE}

clean:
	rm -f $(TARGETS) *.vcd
