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
        clk = 1;
        rst = 1;
        rnd = 0;
        dut.MEM.mem[0] = {32'h00100093, 32'h00200113, 32'h002081b3, 32'h00200113}; // ADDI x1, x0, 1, ADDI x2, x0, 2. ADD  x3, x1, x2

        // Apply reset
        repeat (2) @(posedge clk);
        rst = 0;
        dut.MEM.mem[0] = {32'h00100093, 32'h00200113, 32'h002081b3, 32'h00200113}; // ADDI x1, x0, 1, ADDI x2, x0, 2. ADD  x3, x1, x2
        dut.MEM.mem[1] = {32'h00300293, 32'h00300313, 32'h00310333, 32'h00300313}; // ADDI x5, x0, 3, ADDI x6, x0, 3. ADD  x6, x5, x6
        
        $display("--- Reset released ---");

        // Run simulation
        repeat (40) @(posedge clk);

        // End simulation
        $display("--- Simulation finished ---");
        $finish;
    end

endmodule
