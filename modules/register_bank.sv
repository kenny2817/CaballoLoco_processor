module reg_bank # (
    parameter DATA_WIDTH,
    parameter NUM_REG,
    localparam SELECT_WIDTH = $clog2(NUM_REG)
) (
    input logic clk,
    input logic rst,
    input logic i_write_enable,
    input logic [SELECT_WIDTH -1 : 0] i_write_select,
    input logic [DATA_WIDTH -1 : 0] i_write_data,
    output logic [DATA_WIDTH -1 : 0] o_read_data [NUM_REG]
);

    logic [DATA_WIDTH -1 : 0] data [NUM_REG];

    generate
        genvar i;
        for (i = 0; i < NUM_REG; i++) begin
            assign o_read_data[i] = data[i];
        end
    endgenerate
    

    always_ff @(posedge clk, posedge rst) begin
        if (rst)
            for (int i = 0; i < NUM_REG; i++)
                data[i] = '0;
        else
            if (i_write_enable && i_write_select < NUM_REG)
                data[i_write_select] = i_write_data;
    end
endmodule


module reg_bank_tb;

    localparam DATA_WIDTH = 8;
    localparam NUM_REG = 6;

    logic clk = 0, rst;
    logic write_enable;
    logic [$clog2(NUM_REG) -1 : 0] write_select;
    logic [DATA_WIDTH - 1 : 0] write_data;
    wire [DATA_WIDTH - 1 : 0] read_data [NUM_REG];

    reg_bank #( 
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
        rst = 1; #10;
        rst = 0;
        write_enable = 1; write_select = 2; write_data = 8'hAA; #10;
        write_enable = 1; write_select = 1; write_data = 8'hBB; #10;
        write_enable = 1; write_select = 2; write_data = 8'hBB; #10;
        write_enable = 0; write_select = 2; write_data = 8'hAA; #10;
        write_enable = 1; write_select = 7; write_data = 8'hCC; #10;
        $finish;
    end

    initial $monitor("t=%3t | en=%b | sel_in=%d | in=%h | out=%h %h %h %h %h %h", 
        $time, write_enable, write_select, write_data, 
        read_data[0], read_data[1], read_data[2], read_data[3], read_data[4], read_data[5]
    );

endmodule