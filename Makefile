IFLAGS = -g2012
MODULES_DIR = modules
TB_DIR = tb
PKG_DIR = pkgs
TARGETS = mux demux cmp register alu register_bank pci opd_32 cbs

.PHONY: all $(TARGETS) clean

icarus: $(TARGETS)

mux: $(MODULES_DIR)/mux.sv $(TB_DIR)/mux_tb.sv
	iverilog $(IFLAGS) -o $@ $^

demux: $(MODULES_DIR)/demux.sv $(TB_DIR)/demux_tb.sv
	iverilog $(IFLAGS) -o $@ $^

register: $(MODULES_DIR)/register.sv $(TB_DIR)/register_tb.sv
	iverilog $(IFLAGS) -o $@ $^

register_bank: $(MODULES_DIR)/register_bank.sv $(TB_DIR)/register_bank_tb.sv
	iverilog $(IFLAGS) -o $@ $^

cmp: $(PKG_DIR)/cmp_pkg.sv $(MODULES_DIR)/cmp.sv $(TB_DIR)/cmp_tb.sv
	iverilog $(IFLAGS) -o $@ $^

alu: $(PKG_DIR)/alu_pkg.sv $(MODULES_DIR)/alu.sv $(TB_DIR)/alu_tb.sv
	iverilog $(IFLAGS) -o $@ $^

pci: $(MODULES_DIR)/pci.sv $(TB_DIR)/pci_tb.sv
	iverilog $(IFLAGS) -o $@ $^

opd_32: $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv  $(MODULES_DIR)/opd_32.sv $(TB_DIR)/opd_32_tb.sv
	iverilog $(IFLAGS) -o $@ $^

cbs: $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv $(MODULES_DIR)/cbs.sv $(MODULES_DIR)/register.sv $(MODULES_DIR)/pci.sv $(MODULES_DIR)/mux.sv $(MODULES_DIR)/opd_32.sv $(MODULES_DIR)/register_bank.sv $(MODULES_DIR)/alu.sv $(MODULES_DIR)/cmp.sv $(TB_DIR)/cbs_tb.sv
	iverilog $(IFLAGS) -o $@ $^

S: $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv  $(MODULES_DIR)/S.sv $(TB_DIR)/S_tb.sv
	iverilog $(IFLAGS) -o $@ $^

clean:
	rm -f $(TARGETS)

VFLAGS = -sv --cc --exe -CFLAGS "-std=c++17" --timing

cbs_v: $(PKG_DIR)/alu_pkg.sv $(PKG_DIR)/cmp_pkg.sv $(PKG_DIR)/opcodes_pkg.sv \
     $(MODULES_DIR)/cbs.sv $(MODULES_DIR)/register.sv $(MODULES_DIR)/pci.sv \
     $(MODULES_DIR)/mux.sv $(MODULES_DIR)/opd_32.sv $(MODULES_DIR)/register_bank.sv \
     $(MODULES_DIR)/alu.sv $(MODULES_DIR)/cmp.sv $(TB_DIR)/cbs_tb.sv
	verilator $(VFLAGS) -o $@ $^
	make -C obj_dir -f Vcbs.mk Vcbs
