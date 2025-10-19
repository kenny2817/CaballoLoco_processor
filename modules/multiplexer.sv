module mux #(
    parameter NUM_INPUTS, 
    parameter DATA_WIDTH
) (
    input logic [DATA_WIDTH - 1 : 0] i_data_bus [NUM_INPUTS], 
    input logic [SELECT_BITS - 1 : 0] i_select,
    output logic [DATA_WIDTH - 1 : 0] o_output
);
    localparam SELECT_BITS = $clog2(NUM_INPUTS);

    always_comb begin
        if (i_select < NUM_INPUTS)
            o_output = i_data_bus[i_select];
        else
            o_output = 'x; 
    end
endmodule


module mux_tb;

    localparam NUM_INPUTS = 6;
    localparam DATA_WIDTH = 8;

    logic [DATA_WIDTH - 1 : 0] data_bus [NUM_INPUTS];
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
        data_bus[0] = 8'hAA; data_bus[1] = 8'hBB; data_bus[2] = 8'hCC; data_bus[3] = 8'hDD; data_bus[4] = 8'hEE; data_bus[5] = 8'hFF;
        select = 0; #10;
        select = 1; #10;
        select = 2; #10;
        select = 7; #10;
        $finish;
    end

    initial $monitor("t=%3t | sel= %2d | out=%b |", $time, select, output_data);

endmodule