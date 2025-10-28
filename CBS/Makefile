IFLAGS = -g2012 -Wall
MODULES_DIR = mod
PKG_DIR = pkg
TB_DIR = tb
# PKGS = $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv
PKGS = $(PKG_DIR)/*
TARGETS = reg_mono reg_bank cmp alu reg_bank_mono opd_32 cbs

define IVERILOG_COMPILE
	@iverilog $(IFLAGS) -s $@_tb -o $@ $^ || (echo "failed - $@"; exit 1)
	@echo "success - $@"
endef

.PHONY: all $(TARGETS) clean

icarus: $(TARGETS)

reg_mono: $(MODULES_DIR)/register_mono.sv ${TB_DIR}/reg_mono_tb.sv
	${IVERILOG_COMPILE}

reg_bank: $(MODULES_DIR)/register_bank.sv ${TB_DIR}/reg_bank_tb.sv
	${IVERILOG_COMPILE}

reg_bank_mono: $(MODULES_DIR)/register_bank_mono.sv ${TB_DIR}/reg_bank_mono_tb.sv
	${IVERILOG_COMPILE}

cmp: $(PKG_DIR)/cmp_pkg.sv $(MODULES_DIR)/comparator.sv ${TB_DIR}/cmp_tb.sv
	${IVERILOG_COMPILE}

alu: $(PKG_DIR)/alu_pkg.sv $(MODULES_DIR)/arithmetic_logic_unit.sv ${TB_DIR}/alu_tb.sv
	${IVERILOG_COMPILE}

opd_32: ${PKGS}  $(MODULES_DIR)/opcode_decoder_32.sv ${TB_DIR}/opd_32_tb.sv
	${IVERILOG_COMPILE}

cbs: ${PKGS} $(MODULES_DIR)/caballosano_single_cycle.sv ${TB_DIR}/cbs_tb.sv\
		$(MODULES_DIR)/register_mono.sv $(MODULES_DIR)/opcode_decoder_32.sv $(MODULES_DIR)/register_bank.sv $(MODULES_DIR)/register_bank_mono.sv \
		$(MODULES_DIR)/arithmetic_logic_unit.sv $(MODULES_DIR)/comparator.sv
	${IVERILOG_COMPILE}

clean:
	rm -f $(TARGETS) *.vcd
