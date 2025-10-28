
module tlb #(
    parameter N_LINES,
    parameter VA_WIDTH,
    parameter PA_WIDTH
) (
    input logic clk,
    input logic rst,

    input logic [VA_WIDTH -1 : 0] i_virtual_addr,

    input logic i_write_enable,
    input logic [VA_WIDTH -1 : 0] i_write__virtual_ddr,
    input logic [VA_WIDTH -1 : 0] i_write_physical_addr,

    output logic o_hit,
    output logic o_exeption,
    output logic [PA_WIDTH -1 : 0] o_physical_addr
);
    localparam LINE_SELECT = $clog2(N_LINES);

    logic [VA_WIDTH -1 : 0] virtual_addrs [N_LINES];
    logic [PA_WIDTH -1 : 0] physical_addrs [N_LINES];
    logic valid_bit [N_LINES];
    logic [LINE_SELECT -1 : 0] oldest_line;

    logic [PA_WIDTH -1 : 0] physical_addr;
    logic hit_found;

    always_comb begin
        hit_found = 1'b0;
        physical_addr = 'x;
        for (int i = 0; i < N_LINES; i++) begin
            if (valid_bit[i] && (virtual_addrs[i] == i_virtual_addr)) begin
                hit_found = 1'b1;
                physical_addr = physical_addrs[i];
            end
        end
        
        o_hit = hit_found;
        o_exeption = !hit_found;
        o_physical_addr = physical_addr;
    end


    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < N_LINES; i++) begin
                valid_bit[i] <= '0;
            end
            oldest_line <= '0;
            hit_found <= '0;
        end else if (i_write_enable) begin
            virtual_addrs[oldest_line] <= i_write__virtual_ddr;
            physical_addrs[oldest_line] <= i_write_physical_addr;
            valid_bit[oldest_line] <= 1'b1;
            oldest_line <= oldest_line + 1'b1;
        end
    end

endmodule

