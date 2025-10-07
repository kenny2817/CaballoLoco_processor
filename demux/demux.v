module demux #(
    parameter NUM_OUTPUTS,
    parameter DATA_WIDTH,
    localparam SELECT_BITS = $clog2(NUM_OUTPUTS)
)
(
    input wire [SELECT_BITS - 1 : 0] i_select,
    input wire [DATA_WIDTH - 1 : 0] i_data_bus,
    output logic [NUM_OUTPUTS * DATA_WIDTH - 1 : 0] o_output
);
    always_comb begin
        o_output = '0;

        if (i_select < NUM_OUTPUTS) begin
            o_output[i_select * DATA_WIDTH +: DATA_WIDTH] = i_data_bus;
        end
    end
endmodule