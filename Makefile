VFLAGS = -g2012
MODULES_DIR = modules
TB_DIR = tb
PKG_DIR = pkgs
TARGETS = mux demux cmp register alu

.PHONY: all $(TARGETS) clean

all: $(TARGETS)

mux: $(MODULES_DIR)/mux.v $(TB_DIR)/mux_tb.v
	iverilog $(VFLAGS) -o $@ $^

demux: $(MODULES_DIR)/demux.v $(TB_DIR)/demux_tb.v
	iverilog $(VFLAGS) -o $@ $^

register: $(MODULES_DIR)/register.v $(TB_DIR)/register_tb.v
	iverilog $(VFLAGS) -o $@ $^

cmp: $(PKG_DIR)/cmp_pkg.sv $(MODULES_DIR)/cmp.sv $(TB_DIR)/cmp_tb.sv
	iverilog $(VFLAGS) -o $@ $^

alu: $(PKG_DIR)/alu_pkg.sv $(MODULES_DIR)/alu.sv $(TB_DIR)/alu_tb.sv
	iverilog $(VFLAGS) -o $@ $^

clean:
	rm -f $(TARGETS)