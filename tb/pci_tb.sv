`timescale 1ns/1ps

module pci_tb;

    logic clk;
    logic sel;
    logic [7:0] immediate;
    logic [7:0] pc;

    pci uut (
        .clk(clk),
        .sel(sel),
        .immediate(immediate),
        .pc(pc)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        sel = 0;
        immediate = 8'd0;

        #10;
        immediate = 8'd42;
        sel = 0;
        #10;
        $display("Caricato PC = %0d (atteso 42)", pc);

        sel = 1;
        #40;
        $display("Dopo incremento, PC = %0d (atteso 46)", pc);

        sel = 0;
        immediate = 8'd100;
        #10;
        $display("Caricato PC = %0d (atteso 100)", pc);

        #20;
        $display("Test completato!");
        $stop;
    end

endmodule
