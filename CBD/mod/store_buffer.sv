import cache_pkg::*;

module stb #(
    parameter VA_WIDTH,
    parameter N_LINES
) (
    input logic clk,
    input logic rst,

    // store
    input mem_data_t                i_store,
    
    // commit ack
    input logic                     i_load_cache,
    input logic                     i_hit_cache,

    // commit
    output mem_data_t               o_commit,

    // stall
    output logic                    o_stall,

    // bypass
    output logic                    o_hit,
    output logic [VA_WIDTH -1 : 0]  o_read_data
);
    localparam LINE_SELECT = $clog2(N_LINES);

    mem_data_t                      buffer [N_LINES];
    
    logic [LINE_SELECT -1 : 0]      oldest_line, newest_line, load_index;
    logic                           hit_cache, load_cache;

    assign o_stall = i_store.enable && buffer[newest_line].enable; // buffer full

    assign o_commit = buffer[oldest_line];

    always_comb begin : load_bypass
        o_hit = 1'b0;
        load_index = 'x; 
        
        for (int i = 0; i < N_LINES; i++) begin
            if (buffer[i].enable && (buffer[i].address == i_store.address)) begin
                o_hit = 1'b1;
                load_index = i;
            end
        end

        o_read_data = buffer[load_index].data;
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < N_LINES; i++) begin
                buffer[i].enable <= '0;
            end
            oldest_line <= '0;
            newest_line <= '0;
            hit_cache <= '0;
            load_cache <= '0;
        end else begin
            hit_cache <= i_hit_cache;
            load_cache <= i_load_cache;
            if (hit_cache && !load_cache && buffer[oldest_line].enable) begin // update if cache hit last cycle
                buffer[oldest_line].enable <= '0;
                oldest_line <= oldest_line + 1'b1;
            end
            if (i_store.enable && !buffer[newest_line].enable) begin // try to store in the buffer
                buffer[newest_line] = i_store;
                newest_line <= newest_line + 1'b1;
            end
        end
    end

endmodule
