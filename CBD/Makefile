IFLAGS = -g2012 -Wall
MODULES_DIR = mod
PKG_DIR = pkg
TB_DIR = tb
# PKGS = $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv
PKGS = $(PKG_DIR)/*
TARGETS = dca stb tlb arb ica mem

define IVERILOG_COMPILE
	@iverilog $(IFLAGS) -s $@_tb -o $@ $^ || (echo "failed - $@"; exit 1)
	@echo "success - $@"
endef
define VERILATOR_COMPILE
    @mkdir -p build/$@
    
    @verilator -Wall -Wno-fatal --binary \
        --Mdir build/$@ \
        --top-module $@_tb \
        -o $@ \
        $(filter-out $@,$^) || \
        (echo "failed - $@"; exit 1)
        
    @cp build/$@/$@ $@
    
    @echo "success - $@"
    @echo "Executable is at $@"
endef

.PHONY: all $(TARGETS) clean

icarus: $(TARGETS)

tlb: ${MODULES_DIR}/translation_lookaside_buffer.sv ${TB_DIR}/tlb_tb.sv
	${IVERILOG_COMPILE}

stb: ${MODULES_DIR}/store_buffer.sv ${TB_DIR}/stb_tb.sv
	${IVERILOG_COMPILE}

dca: ${PKG_DIR}/cache_pkg.sv ${MODULES_DIR}/data_cache.sv ${TB_DIR}/dca_tb.sv
	${VERILATOR_COMPILE}

ica: ${MODULES_DIR}/instruction_cache.sv ${TB_DIR}/ica_tb.sv
	${IVERILOG_COMPILE}

arb: ${MODULES_DIR}/arbiter.sv ${TB_DIR}/arb_tb.sv
	${IVERILOG_COMPILE}

cmp: $(PKG_DIR)/cmp_pkg.sv ${MODULES_DIR}/comparator.sv ${TB_DIR}/cmp_tb.sv
	${IVERILOG_COMPILE}

alu: $(PKG_DIR)/alu_pkg.sv ${MODULES_DIR}/arithmetic_logic_unit.sv ${TB_DIR}/alu_tb.sv
	${IVERILOG_COMPILE}

dme: ${PKG_DIR}/cache_pkg.sv ${MODULES_DIR}/data_cache.sv ${MODULES_DIR}/translation_lookaside_buffer.sv ${MODULES_DIR}/store_buffer.sv ${MODULES_DIR}/data_memory.sv ${TB_DIR}/dme_tb.sv
	${VERILATOR_COMPILE}

mem: ${MODULES_DIR}/memory.sv ${TB_DIR}/mem_tb.sv
	${VERILATOR_COMPILE}

clean:
	rm -f $(TARGETS) *.vcd
