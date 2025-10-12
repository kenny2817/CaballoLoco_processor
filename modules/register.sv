module register # (
    parameter DATA_WIDTH,
    parameter NUM_REG
) (
    input logic clk,
    input logic rst,
    input logic i_write_enable,
    input logic [NUM_REG * DATA_WIDTH - 1 : 0] i_write_data,
    output logic [NUM_REG * DATA_WIDTH - 1 : 0] o_read_data
);
    always_ff @(posedge clk, posedge rst) begin
        if (rst)
            o_read_data <= '0;
        else
            if (i_write_enable)
                o_read_data <= i_write_data;
    end
endmodule


module register_tb;

    localparam DATA_WIDTH = 8;
    localparam NUM_REG = 6;

    logic clk = 0, rst, write_enable;
    logic [NUM_REG * DATA_WIDTH - 1 : 0] write_data;
    logic [NUM_REG * DATA_WIDTH - 1 : 0] read_data;

    register #( 
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REG(NUM_REG)
    ) dut (
        .clk(clk),
        .rst(rst),
        .i_write_enable(write_enable),
        .i_write_data(write_data),
        .o_read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin
        rst = 1;
        #10;
        rst = 0;
        write_enable = 1; write_data = {8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hFF}; #10;
        write_enable = 1; write_data = {8'hAA, 8'hBB, 8'h11, 8'hDD, 8'hEE, 8'hFF}; #10;
        write_enable = 0; #10;
        
        $finish;
    end

    initial $monitor("t=%0t | rst=%b | en=%b | in=%h | out=%h", $time, rst, write_enable, write_data, read_data);

endmodule