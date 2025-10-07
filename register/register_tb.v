`timescale 1ns/1ps

module tb_register;

    logic clk;
    logic rst;
    logic i_enable;
    logic [7:0] i_in;
    logic [7:0] o_out;


    register #( .DATA_WIDTH(8) ) uut( //unit under test
        .clk(clk),
        .rst(rst),
        .i_enable(i_enable),
        .i_in(i_in),
        .o_out(o_out)
    );

    
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        i_enable = 0;
        i_in = '0;

        #15;
        rst = 0;

        i_enable = 1;
        i_in = 8'hA5;
        #10;
        i_in = 8'h3C;         // cambia input
        #10;

        i_enable = 0;
        i_in = 8'hFF;         // cambia input, ma non deve aggiornarsi
        #20;

        i_enable = 1;
        i_in = 8'h55;
        #10;
        
        $finish;
    end

    initial begin
        $monitor("t=%0t | rst=%b | en=%b | in=%h | out=%h", $time, rst, i_enable, i_in, o_out);
    end

endmodule
