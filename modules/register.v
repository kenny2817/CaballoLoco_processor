module register # (
    parameter DATA_WIDTH
)
(
    input logic clk,
    input logic rst,
    input logic i_enable,
    input logic [DATA_WIDTH - 1 : 0] i_in,
    output logic [DATA_WIDTH - 1 : 0] o_out
);

always_ff @(posedge clk or posedge rst) begin //reset to be implemented
    if (rst)
        o_out = '0;
    else if (i_enable)
        o_out <= i_in;
end

endmodule
