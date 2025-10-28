module reg_mono_tb;

    localparam DATA_WIDTH = 8;

    logic clk = 0, rst = 0, write_enable;
    logic [DATA_WIDTH - 1 : 0] write_data;
    wire [DATA_WIDTH - 1 : 0] read_data;

    reg_mono #( 
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .i_write_enable(write_enable),
        .i_write_data(write_data),
        .o_read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin
        write_data = 8'hAA;
        rst = 1; #10;
        rst = 0; #10;
        write_enable = 1; #10;
        write_enable = 1; write_data = 8'h00; #10;
        write_enable = 0; #10;
        $finish;
    end

    initial $monitor("t=%3t | rst=%b | en=%b | in=%h | dut=%h | out=%h |",$time, rst, write_enable, write_data, dut.data, read_data);

endmodule