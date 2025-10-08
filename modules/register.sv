module register # (
    parameter DATA_WIDTH,
    parameter NUM_REG
)
(
    input wire clk,
    input wire [NUM_REG - 1 : 0] i_write_enable,
    input wire [DATA_WIDTH - 1 : 0] i_write_data,
    output logic [NUM_REG * DATA_WIDTH - 1 : 0] o_read_data
);

always_ff @(posedge clk) begin
    for (int i = 0; i < NUM_REG; i++) begin
        if (i_write_enable[i])
            o_read_data[i*DATA_WIDTH +: DATA_WIDTH] <= i_write_data[DATA_WIDTH : 0];
    end
end

endmodule
