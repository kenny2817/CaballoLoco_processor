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
