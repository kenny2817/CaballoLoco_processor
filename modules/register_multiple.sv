module reg_multi # (
    parameter DATA_WIDTH,
    parameter NUM_REG
) (
    input logic clk,
    input logic rst,
    input logic i_write_enable,
    input logic [DATA_WIDTH - 1 : 0] i_write_data [NUM_REG],
    output logic [DATA_WIDTH - 1 : 0] o_read_data [NUM_REG]
);

    logic [DATA_WIDTH - 1 : 0] data [NUM_REG];

    always_ff @(posedge clk, posedge rst) begin
        if (rst)
            for (int i = 0; i < NUM_REG; i++)
                data[i] <= '0;
        else
            if (i_write_enable)
                for (int i = 0; i < NUM_REG; i++)
                    data[i] <= i_write_data[i];
    end
    
    generate
        genvar i;
        for (i = 0; i < NUM_REG; i++) begin
            assign o_read_data[i] = data[i];
        end
    endgenerate

endmodule

module reg_multi_tb;

    localparam DATA_WIDTH = 8;
    localparam NUM_REG = 6;

    logic clk = 0, rst = 0, write_enable;
    logic [DATA_WIDTH - 1 : 0] write_data [NUM_REG];
    wire [DATA_WIDTH - 1 : 0] read_data [NUM_REG];

    reg_multi #( 
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
        write_data[0] = 8'hAA; write_data[1] = 8'hBB; write_data[2] = 8'hCC; write_data[3] = 8'hDD; write_data[4] = 8'hEE; write_data[5] = 8'hFF;
        rst = 1; #10;
        rst = 0; #10;
        write_enable = 1; #10;
        write_enable = 1; write_data[3] = 8'h00; #10;
        write_enable = 0; write_data[5] = 8'h00; #10;
        $finish;
    end

    initial $monitor("t=%3t | rst=%b | en=%b | in=%h %h %h %h %h %h | dut=%h %h %h %h %h %h | out=%h %h %h %h %h %h",$time, rst, write_enable, 
        write_data[0], write_data[1], write_data[2], write_data[3], write_data[4], write_data[5],
        dut.data[0], dut.data[1], dut.data[2], dut.data[3], dut.data[4], dut.data[5],
        read_data[0], read_data[1], read_data[2], read_data[3], read_data[4], read_data[5]
    );

endmodule