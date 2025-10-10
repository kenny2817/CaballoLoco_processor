module demux #(
    parameter NUM_OUTPUTS
) (
    input logic [SELECT_BITS - 1 : 0] i_select,
    input logic i_enable,
    output logic [NUM_OUTPUTS - 1 : 0] o_output
);
    localparam SELECT_BITS = $clog2(NUM_OUTPUTS);
    always_comb begin
        o_output = '0;

        if (i_enable && i_select < NUM_OUTPUTS) begin
            o_output[i_select] = '1;
        end
    end
endmodule