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

        // Apply reset
        repeat (2) @(posedge clk);
        rst = 0;
        // 0C: lw x4, 0(x2)
        // 08: addi x3, x2, 128
        // 04: addi x2, x0, 160
        // 00: addi x1, x0, 0
        dut.MEM.mem[0] = {32'h00012203, 32'h08010193, 32'h0A000113, 32'h00000093};

        // 1C: sw x1, 128(x2)
        // 18: bne x2, x3, -12
        // 14: addi x2, x2, 4
        // 10: add x1, x1, x4
        dut.MEM.mem[1] = {32'h08112023, 32'hFE311AE3, 32'h00410113, 32'h004080B3};

        // dut.MEM.mem[0] = {32'h00100093, 32'h00200113, 32'h002081b3, 32'h00200113}; // ADDI x1, x0, 1, ADDI x2, x0, 2. ADD  x3, x1, x2
        // dut.MEM.mem[1] = {32'h00300293, 32'h00300313, 32'h00310333, 32'h00300313}; // ADDI x5, x0, 3, ADDI x6, x0, 3. ADD  x6, x5, x6

        // array of data to load
        dut.MEM.mem[10] = 128'h00000004000000030000000200000001;
        dut.MEM.mem[11] = 128'h00000008000000070000000600000005;
        dut.MEM.mem[12] = 128'h0000000c0000000b0000000a00000009;
        dut.MEM.mem[13] = 128'h000000100000000f0000000e0000000d;
        dut.MEM.mem[14] = 128'h00000014000000130000001200000011;
        dut.MEM.mem[15] = 128'h00000018000000170000001600000015;
        dut.MEM.mem[16] = 128'h0000001c0000001b0000001a00000019;
        dut.MEM.mem[17] = 128'h000000200000001f0000001e0000001d;
        dut.MEM.mem[18] = 128'h00000024000000230000002200000021;
        dut.MEM.mem[19] = 128'h00000028000000270000002600000025;
        dut.MEM.mem[20] = 128'h0000002c0000002b0000002a00000029;
        dut.MEM.mem[21] = 128'h000000300000002f0000002e0000002d;
        dut.MEM.mem[22] = 128'h00000034000000330000003200000031;
        dut.MEM.mem[23] = 128'h00000038000000370000003600000035;
        dut.MEM.mem[24] = 128'h0000003c0000003b0000003a00000039;
        dut.MEM.mem[25] = 128'h000000400000003f0000003e0000003d;
        dut.MEM.mem[26] = 128'h00000044000000430000004200000041;
        dut.MEM.mem[27] = 128'h00000048000000470000004600000045;
        dut.MEM.mem[28] = 128'h0000004c0000004b0000004a00000049;
        dut.MEM.mem[29] = 128'h000000500000004f0000004e0000004d;
        dut.MEM.mem[30] = 128'h00000054000000530000005200000051;
        dut.MEM.mem[31] = 128'h00000058000000570000005600000055;
        dut.MEM.mem[32] = 128'h0000005c0000005b0000005a00000059;
        dut.MEM.mem[33] = 128'h000000600000005f0000005e0000005d;
        dut.MEM.mem[34] = 128'h00000064000000630000006200000061;
        dut.MEM.mem[35] = 128'h00000068000000670000006600000065;
        dut.MEM.mem[36] = 128'h0000006c0000006b0000006a00000069;
        dut.MEM.mem[37] = 128'h000000700000006f0000006e0000006d;
        dut.MEM.mem[38] = 128'h00000074000000730000007200000071;
        dut.MEM.mem[39] = 128'h00000078000000770000007600000075;
        dut.MEM.mem[40] = 128'h0000007c0000007b0000007a00000079;
        dut.MEM.mem[41] = 128'h000000800000007f0000007e0000007d;

        $display("--- Reset released ---");

        // Run simulation
        repeat (4000) @(posedge clk);

        // End simulation
        $display("--- Simulation finished ---");
        $finish;
    end

endmodule
