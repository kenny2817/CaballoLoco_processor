
typedef enum logic [1:0] { 
    IDLE,                   // ready for store and load
    S_REQUEST,                 // wait mem miss, ready for load
    L_REQUEST,                 // stall, wait load miss
    BOTH_REQUEST                  // stall, wait load miss, store in background
} cache_state;


module dca #(
    parameter N_SECTORS,                                    // number of sectors
    parameter N_LINES,                                      // number of lines per sector
    parameter N_ELEMENTS,                                   // number of elements per line
    parameter N_BYTES,                                      // number of bytes per element
    parameter VA_WIDTH,                                     // virtual address width
    parameter PA_WIDTH,                                     // physical address width (this should be already the tag!)
    parameter ID_WIDTH,                                     // id width for memory requests
    
    localparam ELEMENT_WIDTH = N_BYTES * 8,                 // element width in bits
    localparam LINE_WIDTH    = N_ELEMENTS * ELEMENT_WIDTH,  // line width in bits
    localparam INDEX_WIDTH   = $clog2(N_LINES)              // index width in bits
) (
    input logic                             clk,
    input logic                             rst,
    input logic [INDEX_WIDTH -1 : 0]        rnd,

    input logic                             i_hit, // store buffer bypass
    input logic                             i_enable,
    input logic                             i_is_load,
    input logic [VA_WIDTH -1 : 0]           i_va_load,
    input logic [PA_WIDTH -1 : 0]           i_pa_load,
    input logic [VA_WIDTH -1 : 0]           i_va_store,
    input logic [PA_WIDTH -1 : 0]           i_pa_store,
    input logic [ELEMENT_WIDTH -1 : 0]      i_data_store, 

    output logic                            o_hit,
    output logic                            o_stall,
    output logic [ELEMENT_WIDTH -1 : 0]     o_read_data,

    // mem  
    output logic                            o_mem_enable,
    output logic [PA_WIDTH -1 : 0]          o_mem_addr,
    output logic [LINE_WIDTH -1 : 0]        o_mem_data,
    output logic                            o_mem_type,
    output logic                            o_mem_ack,

    input logic                             i_mem_enable,
    input logic [LINE_WIDTH -1 : 0]         i_mem_data,
    input logic [ID_WIDTH -1 : 0]           i_mem_id_request,
    input logic [ID_WIDTH -1 : 0]           i_mem_id_response
);

    localparam SECTOR_WIDTH = $clog2(N_SECTORS);
    localparam OFFSET_WIDTH = $clog2(N_ELEMENTS);

    logic [LINE_WIDTH -1 : 0]               memory          [N_SECTORS][N_LINES];
    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   tag             [N_SECTORS][N_LINES];
    logic                                   valid_bit       [N_SECTORS][N_LINES];
    logic                                   dirty_bit       [N_SECTORS][N_LINES];

    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   addr_tag;
    logic [SECTOR_WIDTH -1 : 0]             addr_idx;
    logic [OFFSET_WIDTH -1 : 0]             addr_off;
    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   addr_tag_load;
    logic [SECTOR_WIDTH -1 : 0]             addr_idx_load;
    logic [OFFSET_WIDTH -1 : 0]             addr_off_load;
    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   addr_tag_store;
    logic [SECTOR_WIDTH -1 : 0]             addr_idx_store;
    logic [OFFSET_WIDTH -1 : 0]             addr_off_store;
    logic [INDEX_WIDTH -1 : 0]              hit_index;


    logic [INDEX_WIDTH -1 : 0]              rnd_registry[2];
    logic [ID_WIDTH -1 : 0]                 ids_registry[2];
    logic                                   mem_hit     [2];

    cache_state                             state;
    cache_state                             next_state;

    // tasks
    task automatic request_mem(
        input int slot
    );
        o_mem_enable <= 1'b1;
        o_mem_type <= 1'b0;
        o_mem_addr <= {addr_tag, {(OFFSET_WIDTH){1'b0}}};
        rnd_registry[slot] <= rnd;
        ids_registry[slot] <= i_mem_id_request;
    endtask

    task automatic get_from_mem(
        input int slot,
        input logic [SECTOR_WIDTH -1 : 0] idx,
        input logic [PA_WIDTH -OFFSET_WIDTH -1 : 0] tmp_tag
    );
        if (mem_hit[slot]) begin
            // load from mem
            o_mem_ack <= 1'b1;
            tag         [idx][rnd_registry[slot]] <= tmp_tag;
            memory      [idx][rnd_registry[slot]] <= i_mem_data;
            valid_bit   [idx][rnd_registry[slot]] <= 1'b1;
            dirty_bit   [idx][rnd_registry[slot]] <= 1'b0;
        end
    endtask

    task automatic evict_dirty_try_get_mem(
        input int slot,
        input logic [SECTOR_WIDTH -1 : 0] idx,
        input logic [PA_WIDTH -OFFSET_WIDTH -1 : 0] tmp_tag
    );
        if (dirty_bit[idx][rnd_registry[slot]]) begin
            // eviction - buffer accepts write in 1 cycle
            o_mem_enable <= 1'b1;
            o_mem_type <= 1'b1;  // Write
            o_mem_addr <= {tag[idx][rnd_registry[slot]], {OFFSET_WIDTH{1'b0}}};
            o_mem_data <= memory[idx][rnd_registry[slot]];
            dirty_bit[idx][rnd_registry[slot]] <= 1'b0;
        end
        get_from_mem(slot, idx, tmp_tag);
    endtask

    task automatic store_hit(  
    );
        memory[addr_idx_store][hit_index][(addr_off_store +1) * ELEMENT_WIDTH -1 -: ELEMENT_WIDTH] <= i_data_store;
        dirty_bit[addr_idx_store][hit_index] <= 1'b1;
    endtask

    // assignments
    assign addr_tag_load    = i_pa_load[PA_WIDTH -1 : OFFSET_WIDTH];
    assign addr_idx_load    = i_va_load[SECTOR_WIDTH + OFFSET_WIDTH -1 : OFFSET_WIDTH];
    assign addr_off_load    = i_va_load[OFFSET_WIDTH -1 : 0];
    assign addr_tag_store   = i_pa_store[PA_WIDTH -1 : OFFSET_WIDTH];
    assign addr_idx_store   = i_va_store[SECTOR_WIDTH + OFFSET_WIDTH -1 : OFFSET_WIDTH];
    assign addr_off_store   = i_va_store[OFFSET_WIDTH -1 : 0];
    assign addr_tag         = i_is_load ? addr_tag_load : addr_tag_store;
    assign addr_idx         = i_is_load ? addr_idx_load : addr_idx_store;
    assign addr_off         = i_is_load ? addr_off_load : addr_off_store;
    
    assign mem_hit[0]       = i_mem_enable && ids_registry[0] == i_mem_id_response;
    assign mem_hit[1]       = i_mem_enable && ids_registry[1] == i_mem_id_response;


    always_comb begin : hit_logic
        // hit logic
        o_hit = 1'b0;
        hit_index = 'x;
        for (int i = 0; i < N_LINES; i++) begin
            if (valid_bit[addr_idx][i] && (tag[addr_idx][i] == addr_tag)) begin
                o_hit = 1'b1;
                hit_index = i;
            end
        end

        // output logic
        o_read_data = memory[addr_idx][hit_index][(addr_off +1) * ELEMENT_WIDTH -1 -: ELEMENT_WIDTH];
        o_stall = (i_enable && i_is_load && !o_hit);
    end

    always_comb begin : state_machine
        if (i_enable) begin
            next_state = state;
            case (state)
                IDLE: begin
                    if (!o_hit) begin
                        if (i_is_load) begin
                            next_state = L_REQUEST;
                        end else begin
                            next_state = S_REQUEST;
                        end
                    end
                end
                S_REQUEST: begin
                    if (o_hit && !i_is_load) begin
                        next_state = IDLE;
                    end else if (!o_hit && i_is_load) begin
                        next_state = BOTH_REQUEST;
                    end
                end
                L_REQUEST: begin
                    if (o_hit && i_is_load) begin
                        next_state = IDLE;
                    end
                end
                BOTH_REQUEST: begin
                    if (o_hit && i_is_load) begin
                        next_state = S_REQUEST;
                    end
                end
            endcase
        end
    end

    always_ff @( posedge clk or posedge rst) begin : control_flow
        if (rst) begin
            for (int i = 0; i < N_SECTORS; i++) begin
                for (int j = 0; j < N_LINES; j++) begin
                    valid_bit[i][j] <= 1'b0;
                    dirty_bit[i][j] <= 1'b0;
                end
            end
            state <= IDLE;
            o_mem_enable <= 1'b0;
            o_mem_ack <= 1'b0;
        end else begin
            o_mem_ack <= 1'b0;
            o_mem_enable <= 1'b0;
            o_mem_data <= 'x;
            if (i_enable) begin
                state <= next_state;
                case (state)
                    IDLE: begin
                        if (!i_is_load && !o_hit || !o_hit && !i_hit) begin
                            // store or load miss
                            request_mem(0);
                        end
                        if (!i_is_load && o_hit) begin
                            store_hit();
                        end
                    end
                    S_REQUEST: begin
                        if (i_is_load && !o_hit && !i_hit) begin
                            // load miss
                            request_mem(1);
                        end else if (!i_is_load && o_hit) begin
                            store_hit();
                        end else begin
                            evict_dirty_try_get_mem(0, addr_idx_store, addr_tag_store);
                        end
                    end
                    L_REQUEST: begin
                        evict_dirty_try_get_mem(0, addr_idx_load, addr_tag_load);
                    end
                    BOTH_REQUEST: begin
                        evict_dirty_try_get_mem(1, addr_idx_load, addr_tag_load);
                        get_from_mem(0, addr_idx_store, addr_tag_store);
                    end
                endcase
            end
        end
    end

endmodule

