module demux #(
    parameter NUM_OUTPUTS,
    localparam SELECT_BITS = $clog2(NUM_OUTPUTS)
)
(
    input wire [SELECT_BITS - 1 : 0] i_select,
    output reg [NUM_OUTPUTS - 1 : 0] o_output
);
    always_comb begin
        o_output = '0;

        if (i_select < NUM_OUTPUTS) begin
            o_output[i_select] = '1;
        end
    end
endmodule