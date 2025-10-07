VFLAGS = -g2012
MODULES_DIR = modules
TARGETS = mux demux cmp register

.PHONY: all $(TARGETS) clean

all: $(TARGETS)

mux: $(MODULES_DIR)/mux/mux.v $(MODULES_DIR)/mux/mux_tb.v
	iverilog $(VFLAGS) -o $@ $^

demux: $(MODULES_DIR)/demux/demux.v $(MODULES_DIR)/demux/demux_tb.v
	iverilog $(VFLAGS) -o $@ $^

cmp: $(MODULES_DIR)/cmp/cmp.v $(MODULES_DIR)/cmp/cmp_tb.v
	iverilog $(VFLAGS) -o $@ $^

register: $(MODULES_DIR)/register/register.v $(MODULES_DIR)/register/register_tb.v
	iverilog $(VFLAGS) -o $@ $^

clean:
	rm -f $(TARGETS)