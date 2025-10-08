`timescale 1ns/1ns

module register_bank_tb;

    localparam DATA_WIDTH = 8;
    localparam NUM_REG = 6;

    logic clk;
    logic write_enable;
    logic [$clog2(NUM_REG) -1 : 0] write_select;
    logic [DATA_WIDTH - 1 : 0] write_data;
    logic [NUM_REG * DATA_WIDTH - 1 : 0] read_data;

    register_bank #( 
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REG(NUM_REG)
    ) dut (
        .clk(clk),
        .i_write_enable(write_enable),
        .i_write_select(write_select),
        .i_write_data(write_data),
        .o_read_data(read_data)
    );

    
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        write_enable = 1; write_select = 2; write_data = 8'hAA;
        #10;
        write_enable = 1; write_select = 1; write_data = 8'hAA;
        #10;
        write_enable = 1; write_select = 2; write_data = 8'hBB;
        #10;
        write_enable = 0; write_select = 2; write_data = 8'hAA;
        #10;
        write_enable = 1; write_select = 7; write_data = 8'hCC;
        #10;
        
        $finish;
    end

    initial begin
        $monitor("t=%3t | en=%b | sel=%d | in=%h | out=%h", $time, write_enable, write_select, write_data, read_data);
    end

endmodule
