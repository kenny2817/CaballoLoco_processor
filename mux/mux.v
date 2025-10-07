module mux #(
    parameter NUM_INPUTS, 
    parameter DATA_WIDTH,
    localparam SELECT_BITS = $clog2(NUM_INPUTS)
)
(
    input wire [NUM_INPUTS * DATA_WIDTH - 1 : 0] i_data_bus, 
    input wire [SELECT_BITS - 1 : 0] i_select,
    output wire [DATA_WIDTH - 1 : 0] o_output
);
    assign o_output = i_data_bus [i_select * DATA_WIDTH +: DATA_WIDTH];
endmodule
