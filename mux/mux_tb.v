module mux_tb;
    // Parameters
    localparam NUM_INPUTS = 4;
    localparam DATA_WIDTH = 8;

    // Signals
    reg  [NUM_INPUTS * DATA_WIDTH - 1 : 0] data_bus;
    reg  [$clog2(NUM_INPUTS) - 1 : 0] select;
    wire [DATA_WIDTH - 1 : 0] output_data;

    mux #(
        .NUM_INPUTS(NUM_INPUTS),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .i_data_bus(data_bus),
        .i_select(select),
        .o_output(output_data)
    );

    initial begin
        data_bus = {8'hAA, 8'hBB, 8'hCC, 8'hDD};
        select = 0; #10;
        $display("Select=%0d -> Output=%h", select, output_data);

        select = 1; #10;
        $display("Select=%0d -> Output=%h", select, output_data);

        select = 2; #10;
        $display("Select=%0d -> Output=%h", select, output_data);

        select = 3; #10;
        $display("Select=%0d -> Output=%h", select, output_data);

        $finish;
    end
endmodule
