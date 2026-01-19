module reg_bank # (
    parameter DATA_WIDTH,
    parameter NUM_REG,
    localparam SELECT_WIDTH = $clog2(NUM_REG)
) (
    input logic                         clk,
    input logic                         rst,

    input logic                         i_write_enable,
    input logic [SELECT_WIDTH -1 : 0]   i_write_select,
    input logic [DATA_WIDTH -1 : 0]     i_write_data,
    output logic [DATA_WIDTH -1 : 0]    o_read_data [NUM_REG]
);

    logic [DATA_WIDTH -1 : 0] data [NUM_REG];

    // reading
    generate
        assign o_read_data[0] = '0; 
        genvar i;
        for (i = 1; i < NUM_REG; i++) begin
            assign o_read_data[i] = data[i];
        end
    endgenerate

    // writing
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            for (int k = 0; k < NUM_REG; k++) begin
                data[k] <= '0;
            end
        end else if (i_write_enable && i_write_select != 0) begin
            data[i_write_select] <= i_write_data;
        end
    end

endmodule
