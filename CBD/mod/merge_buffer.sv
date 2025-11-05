
module stb #(
    parameter PA_WIDTH,
    parameter REG_WIDTH,
    parameter N_LINES,
    parameter N_BYTES,
) (
    input logic clk,
    input logic rst,

    input logic i_is_store,
    input logic i_was_load,
    input logic i_was_hit_cache, // next step/cycle,
    input logic [PA_WIDTH -1 : 0] i_adress
    input logic [REG_WIDTH -1 : 0] i_write_data,

    output logic                    o_valid_commit,
    output logic [PA_WIDTH -1 : 0]  o_addr_commit,
    output logic [REG_WIDTH -1 : 0] o_data_commit  [N_BYTES],
    output logic                    o_bytes_commit [N_BYTES],

    output logic o_hit,
    output logic o_exeption,
    output logic [REG_WIDTH -1 : 0] o_read_data
);

    localparam LINE_SELECT = $clog2(N_LINES);
    localparam BYTE_SELECT = $clog2(N_BYTES);

    logic [PA_WIDTH - BYTE_SELECT -1 : 0]   cut_address     [N_LINES];
    logic [REG_WIDTH -1 : 0]                data            [N_LINES][N_BYTES];
    logic                                   valid_bytes     [N_LINES][N_BYTES];
    logic                                   valid_bit       [N_LINES];
    
    logic [LINE_SELECT -1 : 0] oldest_line, newest_line, hit_index;
    logic merge;
    logic [PA_WIDTH - BYTE_SELECT -1 : 0] address;
    logic [BYTE_SELECT -1 : 0] offset;


    always_comb begin
        address = i_adress[PA_WIDTH -1 : BYTE_SELECT];
        offset = i_adress[BYTE_SELECT -1 : 0];

        o_hit = 1'b0;
        merge = 1'b0;
        hit_index = '0; 
        
        for (int i = 0; i < N_LINES; i++) begin
            if (valid_bit[i] && (cut_address[i] == address)) begin
                hit_index = i;  
                if (valid_bytes[i][offset])begin
                    // load bypass
                    o_hit = 1'b1;
                    merge = 1'b1;      
                end else begin
                    // store merge
                    merge = hit_index != oldest_line;
                end
            end
        end

        o_exeption = i_is_store && valid_bit[newest_line] && !merge;
        o_read_data = data[hit_index][offset];

        o_valid_commit = valid_bit[oldest_line];
        o_data_commit = data[oldest_line];
        o_addr_commit = {cut_address[oldest_line], {(BYTE_SELECT){1'b0}}};
        o_bytes_commit = valid_bytes[oldest_line];
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_bit <= '0;
            valid_bytes <= '0;
            oldest_line <= '0;
            newest_line <= '0;
        end else begin
            if (i_was_hit_cache && valid_bit[oldest_line] && !i_was_load) begin // update if cache hit last cycle
                valid_bit[oldest_line] <= '0;
                valid_bytes[oldest_line] <= '0;
                oldest_line <= oldest_line + 1'b1;
            end
            if (i_is_store) begin // try to store in the buffer
                if (merge) begin
                    data[hit_index][offset] <= i_write_data;
                    valid_bytes[hit_index][offset] <= 1'b1;
                end else if (!valid_bit[newest_line]) begin
                    cut_address[newest_line] <= address;
                    data[newest_line][offset] <= i_write_data;
                    valid_bit[newest_line] <= 1'b1;
                    valid_bytes[newest_line][offset] <= 1'b1;
                    newest_line <= newest_line + 1'b1;
                end
            end
        end
    end

endmodule