VFLAGS = -g2012
TARGETS = m d c

all: $(TARGETS)

m: mux/mux.v mux/mux_tb.v
	iverilog $(VFLAGS) -o $@ $^ 

d: demux/demux.v demux/demux_tb.v
	iverilog $(VFLAGS) -o $@ $^

c: cmp/cmp.v cmp/cmp_tb.v
	iverilog $(VFLAGS) -o $@ $^

clean:
	rm m d c
