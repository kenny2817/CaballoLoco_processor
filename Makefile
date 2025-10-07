all: mux demux

mux: mux/mux.v mux/mux_tb.v
	iverilog -g2012 -o m mux/mux.v mux/mux_tb.v

demux: demux/demux.v demux/demux_tb.v
	iverilog -g2012 -o d demux/demux.v demux/demux_tb.v

clean:
	rm m d