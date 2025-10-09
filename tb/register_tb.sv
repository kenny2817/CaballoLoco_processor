`timescale 1ns/100ps

module register_tb;

    localparam DATA_WIDTH = 8;
    localparam NUM_REG = 6;

    logic clk;
    logic [NUM_REG - 1 : 0] write_enable;
    logic [DATA_WIDTH - 1 : 0] write_data;
    logic [NUM_REG * DATA_WIDTH - 1 : 0] read_data;

    register #( 
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REG(NUM_REG)
    ) dut (
        .clk(clk),
        .i_write_enable(write_enable),
        .i_write_data(write_data),
        .o_read_data(read_data)
    );

    
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        #10;
        write_enable = 1; write_data = 8'hAA;
        #10;
        write_enable = 4;
        #10;
        write_enable = 0;
        #10;
        
        $finish;
    end

    initial begin
        $monitor("t=%0t | en=%b | in=%h | out=%h", $time, write_enable, write_data, read_data);
    end

endmodule
