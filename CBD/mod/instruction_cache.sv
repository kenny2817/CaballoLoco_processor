
typedef enum logic [0:0] { 
    I_IDLE,                   // ready for miss
    I_REQUEST                 // stall, request memory + save id
} instruction_cache_state;


module ica #(
    parameter REG_WIDTH = 32,                                       // register width
    parameter N_SECTORS,                                            // number of sectors
    parameter N_LINES,                                              // number of lines per sector
    parameter N_BYTES,                                              // number of bytes per element
    parameter VA_WIDTH,                                             // virtual address width
    parameter PA_WIDTH,                                             // physical address width (this should be already the tag!)
    parameter ID_WIDTH,                                             // memory id width
    
    localparam LINE_WIDTH = N_BYTES * 8,                            // line width in bits
    localparam INDEX_WIDTH   = (N_LINES > 1) ? $clog2(N_LINES) : 1  // index width in bits
) (
    input logic                             clk,
    input logic                             rst,
    input logic [INDEX_WIDTH -1 : 0]        rnd,

    input logic [VA_WIDTH -1 : 0]           i_va_addr,
    input logic [PA_WIDTH -1 : 0]           i_pa_addr,

    output logic                            o_miss,
    output logic [REG_WIDTH -1 : 0]         o_read_data,

    // mem  
    output logic                            o_mem_enable,
    output logic [PA_WIDTH -1 : 0]          o_mem_addr,
    output logic                            o_mem_ack,

    input logic                             i_mem_enable,
    input logic [LINE_WIDTH -1 : 0]         i_mem_data,
    input logic [ID_WIDTH -1 : 0]           i_mem_id_request,
    input logic [ID_WIDTH -1 : 0]           i_mem_id_response,
    input logic                             i_mem_in_use  // intra caches ack
);

    localparam SECTOR_WIDTH = $clog2(N_SECTORS);
    localparam OFFSET_WIDTH = $clog2(N_BYTES);
    localparam NOP = '0;

    logic [LINE_WIDTH             -1 : 0]   memory      [N_SECTORS][N_LINES];
    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   tag         [N_SECTORS][N_LINES];
    logic                                   valid_bit   [N_SECTORS][N_LINES];

    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   addr_tag;
    logic [SECTOR_WIDTH           -1 : 0]   addr_idx;
    logic [OFFSET_WIDTH           -1 : 0]   addr_off;
    logic [INDEX_WIDTH            -1 : 0]   hit_index;
    logic [ID_WIDTH               -1 : 0]   mem_id;
    logic                                   hit;
    logic                                   mem_hit;
    logic [INDEX_WIDTH            -1 : 0]   rnd_latch;

    instruction_cache_state                 state;

    // assignments
    assign addr_tag     = i_pa_addr[PA_WIDTH -1 : OFFSET_WIDTH];
    assign addr_idx     = i_va_addr[SECTOR_WIDTH + OFFSET_WIDTH -1 : OFFSET_WIDTH];
    assign addr_off     = {i_va_addr[OFFSET_WIDTH -1 : 2], 2'd0}; // word aligned

    assign o_miss      = !hit;

    //  memory request
    // assign o_mem_enable = (state == I_REQUEST);
    assign o_mem_addr   = {addr_tag, {OFFSET_WIDTH{1'b0}}};

    // memory response
    assign mem_hit      = i_mem_enable && (mem_id == i_mem_id_response);
    assign o_mem_ack    = (state == I_REQUEST) && mem_hit;
    
    always_comb begin : hit_logic
        // hit logic
        hit = 1'b0;
        hit_index = 'x;
        for (int i = 0; i < N_LINES; i++) begin
            if (valid_bit[addr_idx][i] && (tag[addr_idx][i] == addr_tag)) begin
                hit = 1'b1;
                hit_index = INDEX_WIDTH'(i);
            end
        end

        // output logic
        o_read_data = hit ? memory[addr_idx][hit_index][(addr_off * 8) + REG_WIDTH -1 -: REG_WIDTH] : NOP;
    end

    always_ff @( posedge clk or posedge rst) begin : control_flow
        if (rst) begin
            for (int i = 0; i < N_SECTORS; i++) begin
                for (int j = 0; j < N_LINES; j++) begin
                    valid_bit[i][j] <= 1'b0;
                end
            end
            state <= I_IDLE;
            o_mem_enable <= 1'b0;
        end else begin
            case (state)
                I_IDLE: begin
                    if (!hit && !i_mem_in_use) begin
                        state       <= I_REQUEST;
                        mem_id      <= i_mem_id_request;
                        rnd_latch   <= rnd;
                        o_mem_enable <= 1'b1;
                    end
                end
                I_REQUEST: begin
                    o_mem_enable <= 1'b0;
                    if (mem_hit) begin
                        state <= I_IDLE;
                        tag         [addr_idx][rnd_latch] <= addr_tag;
                        valid_bit   [addr_idx][rnd_latch] <= 1'b1;
                        memory      [addr_idx][rnd_latch] <= i_mem_data;
                    end
                end
            endcase
        end
    end

endmodule

