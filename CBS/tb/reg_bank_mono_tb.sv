module reg_bank_mono_tb;

    localparam DATA_WIDTH = 8;
    localparam NUM_REG = 6;

    logic clk = 0, rst;
    logic write_enable;
    logic [$clog2(NUM_REG) -1 : 0] select;
    logic [DATA_WIDTH - 1 : 0] write_data;
    logic [DATA_WIDTH - 1 : 0] read_data;

    reg_bank_mono #( 
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REG(NUM_REG)
    ) dut (
        .clk(clk),
        .rst(rst),
        .i_write_enable(write_enable),
        .i_select(select),
        .i_write_data(write_data),
        .o_read_data(read_data)
    );
    
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        #10;
        rst = 0;
        write_enable = 1; select = 2; write_data = 8'hAA; #10;
        write_enable = 1; select = 1; write_data = 8'hBB; #10;
        write_enable = 1; select = 2; write_data = 8'hBB; #10;
        write_enable = 0; select = 2; write_data = 8'hAA; #10;
        write_enable = 1; select = 7; write_data = 8'hCC; #10;
        $finish;
    end

    initial $monitor(
        "t=%3t | en=%b | sel=%d | in=%h | out=%h", 
        $time, write_enable, select, write_data, read_data
    );

endmodule