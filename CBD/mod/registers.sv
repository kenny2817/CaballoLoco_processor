module registers 
    import const_pkg::*;
(
    input logic                         clk,
    input logic                         rst,

    input logic                         i_write_enable,
    input logic [REG_ADDR   - 1 : 0]   i_write_select,
    input logic [REG_WIDTH  - 1 : 0]   i_write_data,

    input logic [REG_ADDR   - 1 : 0]   i_read_select_a,
    input logic [REG_ADDR   - 1 : 0]   i_read_select_b,

    output logic [REG_WIDTH - 1 : 0]   o_read_data_a,
    output logic [REG_WIDTH - 1 : 0]   o_read_data_b
);

    logic [REG_WIDTH - 1 : 0] reg_array [REG_NUM];

    assign o_read_data_a = reg_array[i_read_select_a];
    assign o_read_data_b = reg_array[i_read_select_b];

    always_ff @( posedge clk, posedge rst ) begin : write_regs
        if (rst) begin
            for (int i = 0; i < REG_NUM; i++) begin
                reg_array[i] <= '0;
            end
        end else if (i_write_enable) begin
            reg_array[i_write_select] <= i_write_data;
        end
    end

endmodule