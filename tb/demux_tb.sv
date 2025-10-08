module demux_tb;
    localparam NUM_OUTPUTS = 5;

    logic [$clog2(NUM_OUTPUTS) -1 : 0] select;
    logic enable;
    logic [NUM_OUTPUTS - 1 : 0] output_data;

    demux #(
        .NUM_OUTPUTS(NUM_OUTPUTS)
    ) dut (
        .i_select(select),
        .i_enable(enable),
        .o_output(output_data)
    );

    initial begin
        enable = '1; select = 0; #10;
        $display("Select=%0d -> Output= %b", select, output_data);
        
        enable = '0; select = 1; #10;
        $display("Select=%0d -> Output= %b", select, output_data);
        
        enable = '1; select = 2; #10;
        $display("Select=%0d -> Output= %b", select, output_data);
        
        enable = '1; select = 7; #10;
        $display("Select=%0d -> Output= %b", select, output_data);

        $finish;
    end
    
endmodule