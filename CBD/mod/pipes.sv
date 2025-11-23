
import pipes_pkg::*;

module pipe #(
    type CABLE_T
) (
    input logic     clk,
    input logic     rst,
    input logic     enable,

    input CABLE_T   i_pipe,
    output CABLE_T  o_pipe,
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_pipe <= '0;
        end else if (enable) begin
            o_pipe <= i_pipe;
        end
    end
endmodule
