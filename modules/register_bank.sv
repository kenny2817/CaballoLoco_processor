module register_bank # (
    parameter DATA_WIDTH,
    parameter NUM_REG,
    localparam SELECT_WIDTH = $clog2(NUM_REG)
) (
    input logic clk,
    input logic rst,
    input logic i_write_enable,
    input logic [SELECT_WIDTH -1 : 0] i_write_select,
    input logic [DATA_WIDTH -1 : 0] i_write_data,
    output logic [NUM_REG * DATA_WIDTH -1 : 0] o_read_data
);
    always_ff @(posedge clk, posedge rst) begin
        if (rst)
            o_read_data <= '0;
        else
            if (i_write_enable && i_write_select < NUM_REG)
                o_read_data[i_write_select * DATA_WIDTH +: DATA_WIDTH] <= i_write_data[DATA_WIDTH : 0];
    end
endmodule


module register_bank_tb;

    localparam DATA_WIDTH = 8;
    localparam NUM_REG = 6;

    logic clk = 0, rst;
    logic write_enable;
    logic [$clog2(NUM_REG) -1 : 0] write_select;
    logic [DATA_WIDTH - 1 : 0] write_data;
    logic [NUM_REG * DATA_WIDTH - 1 : 0] read_data;

    register_bank #( 
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REG(NUM_REG)
    ) dut (
        .clk(clk),
        .rst(rst),
        .i_write_enable(write_enable),
        .i_write_select(write_select),
        .i_write_data(write_data),
        .o_read_data(read_data)
    );
    
    always #5 clk = ~clk;

    initial begin
        rst = 1;
        #10;
        rst = 0;
        write_enable = 1; write_select = 2; write_data = 8'hAA; #10;
        write_enable = 1; write_select = 1; write_data = 8'hAA; #10;
        write_enable = 1; write_select = 2; write_data = 8'hBB; #10;
        write_enable = 0; write_select = 2; write_data = 8'hAA; #10;
        write_enable = 1; write_select = 7; write_data = 8'hCC; #10;
        $finish;
    end

    initial $monitor("t=%3t | en=%b | sel=%d | in=%h | out=%h", $time, write_enable, write_select, write_data, read_data);

endmodule