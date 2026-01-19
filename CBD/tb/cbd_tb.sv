`timescale 1ns/1ps

module cbd_tb;

// CLOCK AND RESET ======================================================
    localparam CLK_PERIOD = 10; // 100 MHz
    
    logic         clk;
    logic         rst;
    logic [0 : 0] rnd;

// DUT ==================================================================
    cbd dut (
        .clk(clk),
        .rst(rst),
        .rnd(rnd)
    );

// CLOCK GENERATION =====================================================
    always #(CLK_PERIOD / 2) clk <= ~clk;

// MAIN TEST SEQUENCE ===================================================
    initial begin
        $display("--- Starting CBD Testbench ---");

        // VCD dump
        $dumpfile("cbd_tb.vcd");
        $dumpvars(0, cbd_tb);

        // Initial values
        clk = 0;
        rst = 1;
        rnd = 0;

        // Apply reset
        repeat (5) @(posedge clk);
        rst = 0;
        $display("--- Reset released ---");

        // Run simulation
        repeat (100) @(posedge clk);

        // End simulation
        $display("--- Simulation finished ---");
        $finish;
    end

endmodule
