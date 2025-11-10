module reg_bank_mono # (
    parameter DATA_WIDTH,
    parameter NUM_REG,
    localparam SELECT_WIDTH = $clog2(NUM_REG)
) (
    input logic                         clk,
    input logic                         rst,

    input logic                         i_write_enable,
    input logic [SELECT_WIDTH -1 : 0]   i_select,
    input logic [DATA_WIDTH -1 : 0]     i_write_data,
    output logic [DATA_WIDTH -1 : 0]    o_read_data
);

    logic [DATA_WIDTH -1 : 0] data [NUM_REG];
    
    assign o_read_data = (i_select < NUM_REG) ? data[i_select] : 'x;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            for (int i = 0; i < NUM_REG; i++) begin
                data[i] = '0;
            end
        end else if (i_write_enable && i_select < NUM_REG) begin
            data[i_select] = i_write_data;
        end
    end
endmodule
