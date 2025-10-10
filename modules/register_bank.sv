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
