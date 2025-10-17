IFLAGS = -g2012
MODULES_DIR = modules
PKG_DIR = pkgs
PKGS = $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv
TARGETS = mux demux cmp register alu register_bank pci opd_32 cbs register_mono register_bank_mono

define IVERILOG_COMPILE
    iverilog $(IFLAGS) -s $@_tb -o $@ $^
endef

.PHONY: all $(TARGETS) clean

icarus: $(TARGETS)

mux: $(MODULES_DIR)/mux.sv
	${IVERILOG_COMPILE}

demux: $(MODULES_DIR)/demux.sv
	${IVERILOG_COMPILE}

register: $(MODULES_DIR)/register.sv
	${IVERILOG_COMPILE}

register_bank: $(MODULES_DIR)/register_bank.sv
	${IVERILOG_COMPILE}

register_bank_mono: $(MODULES_DIR)/register_bank_mono.sv
	${IVERILOG_COMPILE}

cmp: $(PKG_DIR)/cmp_pkg.sv $(MODULES_DIR)/cmp.sv
	${IVERILOG_COMPILE}

alu: $(PKG_DIR)/alu_pkg.sv $(MODULES_DIR)/alu.sv
	${IVERILOG_COMPILE}

pci: $(MODULES_DIR)/pci.sv
	${IVERILOG_COMPILE}

opd_32: ${PKGS}  $(MODULES_DIR)/opd_32.sv
	${IVERILOG_COMPILE}

cbs: ${PKGS} $(MODULES_DIR)/cbs.sv $(MODULES_DIR)/register.sv $(MODULES_DIR)/register_mono.sv $(MODULES_DIR)/pci.sv $(MODULES_DIR)/mux.sv $(MODULES_DIR)/opd_32.sv $(MODULES_DIR)/register_bank.sv $(MODULES_DIR)/register_bank_mono.sv $(MODULES_DIR)/alu.sv $(MODULES_DIR)/cmp.sv
	${IVERILOG_COMPILE}

register_mono: $(MODULES_DIR)/register_mono.sv
	${IVERILOG_COMPILE}

S: ${PKGS}  $(MODULES_DIR)/S.sv
	${IVERILOG_COMPILE}

clean:
	rm -f $(TARGETS)
