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
        enable = '0; select = 1; #10;
        enable = '1; select = 2; #10;
        enable = '1; select = 7; #10;
        $finish;
    end
    
    initial $monitor("t=%3t | sel= %2d | out=%b |", $time, select, output_data);
    
endmodule