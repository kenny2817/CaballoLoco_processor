module demux_tb;
    localparam NUM_OUTPUTS = 5;

    reg [$clog2(NUM_OUTPUTS) -1 : 0] select;
    wire [NUM_OUTPUTS - 1 : 0] output_data;

    demux #(
        .NUM_OUTPUTS(NUM_OUTPUTS)
    ) dut (
        .i_select(select),
        .o_output(output_data)
    );

    initial begin
        select = 0; #10;
        $display("Select=%0d -> Output= %b", select, output_data);
        
        select = 1; #10;
        $display("Select=%0d -> Output= %b", select, output_data);
        
        select = 2; #10;
        $display("Select=%0d -> Output= %b", select, output_data);
        
        select = 7; #10;
        $display("Select=%0d -> Output= %b", select, output_data);

        $finish;
    end
    
endmodule