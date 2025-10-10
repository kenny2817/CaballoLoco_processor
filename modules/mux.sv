module mux #(
    parameter NUM_INPUTS, 
    parameter DATA_WIDTH
) (
    input logic [NUM_INPUTS * DATA_WIDTH - 1 : 0] i_data_bus, 
    input logic [SELECT_BITS - 1 : 0] i_select,
    output logic [DATA_WIDTH - 1 : 0] o_output
);
    localparam SELECT_BITS = $clog2(NUM_INPUTS);
    always_comb begin
        if (i_select < NUM_INPUTS)
            o_output = i_data_bus[i_select * DATA_WIDTH +: DATA_WIDTH];
        else
            o_output = 'x; 
    end
endmodule
