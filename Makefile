VFLAGS = -g2012
MODULES_DIR = modules
TB_DIR = tb
PKG_DIR = pkgs
TARGETS = mux demux cmp register alu pci

.PHONY: all $(TARGETS) clean

all: $(TARGETS)

mux: $(MODULES_DIR)/mux.sv $(TB_DIR)/mux_tb.sv
	iverilog $(VFLAGS) -o $@ $^

demux: $(MODULES_DIR)/demux.sv $(TB_DIR)/demux_tb.sv
	iverilog $(VFLAGS) -o $@ $^

register: $(MODULES_DIR)/register.sv $(TB_DIR)/register_tb.sv
	iverilog $(VFLAGS) -o $@ $^

cmp: $(PKG_DIR)/cmp_pkg.sv $(MODULES_DIR)/cmp.sv $(TB_DIR)/cmp_tb.sv
	iverilog $(VFLAGS) -o $@ $^

alu: $(PKG_DIR)/alu_pkg.sv $(MODULES_DIR)/alu.sv $(TB_DIR)/alu_tb.sv
	iverilog $(VFLAGS) -o $@ $^

pci: $(MODULES_DIR)/pci.sv $(TB_DIR)/pci_tb.sv
	iverilog $(VFLAGS) -o $@ $^

clean:
	rm -f $(TARGETS)

