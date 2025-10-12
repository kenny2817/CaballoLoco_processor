IFLAGS = -g2012
MODULES_DIR = modules
PKG_DIR = pkgs
TARGETS = mux demux cmp register alu register_bank pci opd_32 cbs

.PHONY: all $(TARGETS) clean

icarus: $(TARGETS)

mux: $(MODULES_DIR)/mux.sv
	iverilog $(IFLAGS) -o $@ $^

demux: $(MODULES_DIR)/demux.sv
	iverilog $(IFLAGS) -o $@ $^

register: $(MODULES_DIR)/register.sv
	iverilog $(IFLAGS) -o $@ $^

register_bank: $(MODULES_DIR)/register_bank.sv
	iverilog $(IFLAGS) -o $@ $^

cmp: $(PKG_DIR)/cmp_pkg.sv $(MODULES_DIR)/cmp.sv
	iverilog $(IFLAGS) -o $@ $^

alu: $(PKG_DIR)/alu_pkg.sv $(MODULES_DIR)/alu.sv
	iverilog $(IFLAGS) -o $@ $^

pci: $(MODULES_DIR)/pci.sv
	iverilog $(IFLAGS) -o $@ $^

opd_32: $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv  $(MODULES_DIR)/opd_32.sv
	iverilog $(IFLAGS) -o $@ $^

cbs: $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv $(MODULES_DIR)/cbs.sv $(MODULES_DIR)/register.sv $(MODULES_DIR)/pci.sv $(MODULES_DIR)/mux.sv $(MODULES_DIR)/opd_32.sv $(MODULES_DIR)/register_bank.sv $(MODULES_DIR)/alu.sv $(MODULES_DIR)/cmp.sv
	iverilog $(IFLAGS) -o $@ $^

S: $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv  $(MODULES_DIR)/S.sv
	iverilog $(IFLAGS) -o $@ $^

clean:
	rm -f $(TARGETS)
