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


module mux_tb;

    localparam NUM_INPUTS = 6;
    localparam DATA_WIDTH = 8;

    logic [NUM_INPUTS * DATA_WIDTH - 1 : 0] data_bus;
    logic [$clog2(NUM_INPUTS) - 1 : 0] select;
    logic [DATA_WIDTH - 1 : 0] output_data;

    mux #(
        .NUM_INPUTS(NUM_INPUTS),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .i_data_bus(data_bus),
        .i_select(select),
        .o_output(output_data)
    );

    initial begin
        data_bus = {8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hFF};
        select = 0; #10;
        select = 1; #10;
        select = 2; #10;
        select = 7; #10;
        $finish;
    end

    initial $monitor("t=%3t | sel= %2d | out=%b |", $time, select, output_data);

endmodule