module demux_tb;
    localparam NUM_OUTPUTS = 5;
    localparam DATA_WIDTH = 8;

    reg [DATA_WIDTH - 1 : 0] data_bus;
    reg [$clog2(NUM_OUTPUTS) -1 : 0] select;
    wire [NUM_OUTPUTS * DATA_WIDTH - 1 : 0] output_data;

    demux #(
        .NUM_OUTPUTS(NUM_OUTPUTS),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .i_data_bus(data_bus),
        .i_select(select),
        .o_output(output_data)
    );

    initial begin
        data_bus = 8'hAA;
        
        select = 0; #10;
        $display("Select=%0d -> Output= %h", select, output_data);
        
        select = 1; #10;
        $display("Select=%0d -> Output= %h", select, output_data);
        
        select = 2; #10;
        $display("Select=%0d -> Output= %h", select, output_data);
        
        select = 7; #10;
        $display("Select=%0d -> Output= %h", select, output_data);

        $finish;
    end
    
endmodule