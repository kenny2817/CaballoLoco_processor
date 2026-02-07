module program_counter # 
    import const_pkg::*;
(
    input logic                         clk,
    input logic                         rst,

    input logic                         i_write_enable,
    input logic [REG_WIDTH - 1 : 0]     i_write_data,
    
    output logic [REG_WIDTH - 1 : 0]    o_read_data
);

    logic [REG_WIDTH - 1 : 0] data;

    assign o_read_data = data;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            data <= '0;
        end else if (i_write_enable) begin
            data <= i_write_data;
        end
    end
    
endmodule
