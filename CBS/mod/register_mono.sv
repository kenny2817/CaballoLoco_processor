module reg_mono # (
    parameter DATA_WIDTH
) (
    input logic clk,
    input logic rst,
    input logic i_write_enable,
    input logic [DATA_WIDTH - 1 : 0] i_write_data,
    output logic [DATA_WIDTH - 1 : 0] o_read_data
);

    logic [DATA_WIDTH - 1 : 0] data;

    always_ff @(posedge clk, posedge rst) begin
        if (rst)
            data <= '0;
        else
            if (i_write_enable)
                data <= i_write_data;
    end
    
    assign o_read_data = data;

endmodule
