IFLAGS = -g2012 -Wall
MODULES_DIR = mod
PKG_DIR = pkg
TB_DIR = tb
# PKGS = $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv
PKGS = $(PKG_DIR)/*
TARGETS = dca stb tlb arb ica

define IVERILOG_COMPILE
	@iverilog $(IFLAGS) -s $@_tb -o $@ $^ || (echo "failed - $@"; exit 1)
	@echo "success - $@"
endef

.PHONY: all $(TARGETS) clean

icarus: $(TARGETS)

tlb: ${MODULES_DIR}/translation_lookaside_buffer.sv ${TB_DIR}/tlb_tb.sv
	${IVERILOG_COMPILE}

stb: ${MODULES_DIR}/store_buffer.sv ${TB_DIR}/stb_tb.sv
	${IVERILOG_COMPILE}

dca: ${MODULES_DIR}/data_cache.sv ${TB_DIR}/dca_tb.sv
	${IVERILOG_COMPILE}

ica: ${MODULES_DIR}/instruction_cache.sv ${TB_DIR}/ica_tb.sv
	${IVERILOG_COMPILE}

arb: ${MODULES_DIR}/arbiter.sv ${TB_DIR}/arb_tb.sv
	${IVERILOG_COMPILE}


clean:
	rm -f $(TARGETS) *.vcd
