
module stb #(
    parameter VA_WIDTH,
    parameter N_LINES
) (
    input logic clk,
    input logic rst,

    // store
    input logic                     i_is_store,
    input logic [VA_WIDTH -1 : 0]   i_adress,
    input logic [VA_WIDTH -1 : 0]   i_write_data,
    
    // commit ack
    input logic                     i_load_cache,
    input logic                     i_hit_cache,

    // commit
    output logic                    o_valid_commit,
    output logic [VA_WIDTH -1 : 0]  o_data_commit,
    output logic [VA_WIDTH -1 : 0]  o_addr_commit,

    // stall
    output logic                    o_stall,

    // bypass
    output logic                    o_hit,
    output logic [VA_WIDTH -1 : 0]  o_read_data
);
    localparam LINE_SELECT = $clog2(N_LINES);

    logic [VA_WIDTH -1 : 0]         address     [N_LINES];
    logic [VA_WIDTH -1 : 0]         data        [N_LINES];
    logic                           valid_bit   [N_LINES];
    
    logic [LINE_SELECT -1 : 0]      oldest_line, newest_line, load_index;
    logic                           hit_cache, load_cache;

    assign o_stall = i_is_store && valid_bit[newest_line];
    assign o_valid_commit = valid_bit[oldest_line];
    assign o_data_commit = data[oldest_line];
    assign o_addr_commit = address[oldest_line];

    always_comb begin : load_bypass
        o_hit = 1'b0;
        load_index = 'x; 
        
        for (int i = 0; i < N_LINES; i++) begin
            if (valid_bit[i] && (address[i] == i_adress)) begin
                o_hit = 1'b1;
                load_index = i;
            end
        end

        o_read_data = data[load_index];
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < N_LINES; i++) begin
                valid_bit[i] <= '0;
            end
            oldest_line <= '0;
            newest_line <= '0;
            hit_cache <= '0;
            load_cache <= '0;
        end else begin
            hit_cache <= i_hit_cache;
            load_cache <= i_load_cache;
            if (hit_cache && !load_cache && valid_bit[oldest_line]) begin // update if cache hit last cycle
                valid_bit[oldest_line] <= '0;
                oldest_line <= oldest_line + 1'b1;
            end
            if (i_is_store && !valid_bit[newest_line]) begin // try to store in the buffer
                address[newest_line] <= i_adress;
                data[newest_line] <= i_write_data;
                valid_bit[newest_line] <= 1'b1;
                newest_line <= newest_line + 1'b1;
            end
        end
    end

endmodule
