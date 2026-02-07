
module pipe 
    import cables_pkg::*;
#(
    type CABLE_T,
    parameter CABLE_T FLUSH_VALUE = '0
) (
    input logic     clk,
    input logic     rst,
    input logic     enable,
    input logic     flush,

    input CABLE_T   i_pipe,
    output CABLE_T  o_pipe
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_pipe <= '0;
        end else if (flush) begin
            o_pipe <= FLUSH_VALUE;
        end else if (enable) begin
            o_pipe <= i_pipe;
        end
    end
endmodule
