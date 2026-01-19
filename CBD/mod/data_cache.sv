
import cache_pkg::*;

typedef enum logic [1:0] { 
    D_IDLE,                   // ready for store and load
    D_S_REQUEST,                 // wait mem miss, ready for load
    D_L_REQUEST,                 // stall, wait load miss
    D_BOTH_REQUEST                  // stall, wait load miss, store in background
} data_cache_state;

module dca #(
    parameter REG_WIDTH = 32,                               // register width in bits
    parameter N_SECTORS,                                    // number of sectors
    parameter N_LINES,                                      // number of lines per sector
    parameter N_BYTES,                                      // number of bytes per line
    parameter PA_WIDTH,                                     // physical address width (this should be already the tag!)
    parameter ID_WIDTH,                                     // id width for memory requests
    
    localparam LINE_WIDTH    = N_BYTES * 8,              // line width in bits
    localparam INDEX_WIDTH   = $clog2(N_LINES)              // index width in bits
) (
    input logic                             clk,
    input logic                             rst,
    input logic [INDEX_WIDTH -1 : 0]        rnd,

    input logic                             i_hit, // store buffer bypass
    input mem_data_t                        i_load,
    input mem_data_t                        i_store,
    input logic [PA_WIDTH -1 : 0]           i_pa,

    output logic                            o_hit,
    output logic                            o_miss,
    output logic [REG_WIDTH -1 : 0]         o_read_data,

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
    localparam OFFSET_WIDTH = $clog2(N_BYTES);

    typedef struct packed {
        logic [SECTOR_WIDTH -1 : 0]             index;
        logic [OFFSET_WIDTH -1 : 0]             offset;
    } index_offset_t;

    typedef struct packed {
        logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   tag;
        logic [INDEX_WIDTH -1 : 0]              rnd;
        logic [ID_WIDTH -1 : 0]                 id;
    } tag_rnd_id_t;

    logic [LINE_WIDTH -1 : 0]               memory      [N_SECTORS][N_LINES];
    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   tag         [N_SECTORS][N_LINES];
    logic                                   valid_bit   [N_SECTORS][N_LINES];
    logic                                   dirty_bit   [N_SECTORS][N_LINES];

    index_offset_t                          addr_load;
    index_offset_t                          addr_store;
    index_offset_t                          addr_data;
    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   addr_tag;
    logic [INDEX_WIDTH -1 : 0]              hit_index;

    tag_rnd_id_t                            registry    [2];

    logic                                   mem_hit     [2];

    logic [LINE_WIDTH -1 : 0]                line_read;
    logic [31 : 0]                           word_read;
    logic [15 : 0]                           half_read;
    logic [7 : 0]                            byte_read;


    data_cache_state                         state;
    data_cache_state                         next_state;

    // tasks
        task automatic request_mem(
            input logic [0 : 0] slot
        );
            o_mem_enable <= 1'b1;
            o_mem_type <= 1'b0;
            o_mem_addr <= {addr_tag, {(OFFSET_WIDTH){1'b0}}};
            registry[slot].tag <= addr_tag;
            registry[slot].rnd <= rnd;
            registry[slot].id <= i_mem_id_request;
        endtask

        task automatic get_from_mem(
            input logic [0 : 0] slot,
            input logic [SECTOR_WIDTH -1 : 0] idx
        );
            if (mem_hit[slot]) begin
                // load from mem
                o_mem_ack <= 1'b1;
                tag         [idx][registry[slot].rnd] <= registry[slot].tag;
                memory      [idx][registry[slot].rnd] <= i_mem_data;
                valid_bit   [idx][registry[slot].rnd] <= 1'b1;
                dirty_bit   [idx][registry[slot].rnd] <= 1'b0;
            end
        endtask

        task automatic evict_dirty_try_get_mem(
            input logic [0 : 0] slot,
            input logic [SECTOR_WIDTH -1 : 0] idx
        );
            if (dirty_bit[idx][registry[slot].rnd]) begin
                // eviction - buffer accepts write in 1 cycle
                o_mem_enable <= 1'b1;
                o_mem_type <= 1'b1;  // Write
                o_mem_addr <= {tag[idx][registry[slot].rnd], {OFFSET_WIDTH{1'b0}}};
                o_mem_data <= memory[idx][registry[slot].rnd];
                dirty_bit[idx][registry[slot].rnd] <= 1'b0;
            end
            get_from_mem(slot, idx);
        endtask

        task automatic store_hit(  
        );
            case(i_store.size)
                SIZE_BYTE: memory[addr_store.index][hit_index][(addr_store.offset +1) * 32 -1 -:  8] <= i_store.data[ 7: 0];
                SIZE_HALF: memory[addr_store.index][hit_index][(addr_store.offset +1) * 32 -1 -: 16] <= i_store.data[15: 0];
                SIZE_WORD: memory[addr_store.index][hit_index][(addr_store.offset +1) * 32 -1 -: 32] <= i_store.data[31: 0];
            endcase
            dirty_bit[addr_store.index][hit_index] <= 1'b1;
        endtask

    // assignments
        assign {addr_load.index,  addr_load.offset}  = i_load.address[SECTOR_WIDTH + OFFSET_WIDTH -1 : 0];
        assign {addr_store.index, addr_store.offset} = i_store.address[SECTOR_WIDTH + OFFSET_WIDTH -1 : 0]; 
        assign addr_data  = i_load.enable ? addr_load : addr_store;
        assign addr_tag   = i_pa[PA_WIDTH -1 : OFFSET_WIDTH];
        
        assign mem_hit[0] = i_mem_enable && registry[0].id == i_mem_id_response;
        assign mem_hit[1] = i_mem_enable && registry[1].id == i_mem_id_response;


    always_comb begin : hit_logic
        // hit logic
        o_hit = 1'b0;
        hit_index = 'x;
        for (int i = 0; i < N_LINES; i++) begin
            if (valid_bit[addr_data.index][i] && (tag[addr_data.index][i] == addr_tag)) begin
                o_hit = 1'b1;
                hit_index = i;
            end
        end

        // read data logic
        line_read = memory[addr_data.index][hit_index];
        word_read = line_read[(addr_data.offset +1) * 32 -1 -: 32];
        half_read = line_read[(addr_data.offset +1) * 16 -1 -: 16];
        byte_read = line_read[(addr_data.offset +1) *  8 -1 -:  8];

        if (i_load.use_unsigned) begin
            case (i_load.size)
                SIZE_BYTE: o_read_data = {24'b0, byte_read};
                SIZE_HALF: o_read_data = {16'b0, half_read};
                SIZE_WORD: o_read_data =         word_read ;
                default:   o_read_data =                'x ;
            endcase
        end else begin
            case (i_load.size)
                SIZE_BYTE: o_read_data = {24'b0, {(byte_read[7])},  byte_read};
                SIZE_HALF: o_read_data = {16'b0, {(half_read[15])}, half_read};
                SIZE_WORD: o_read_data =                            word_read ;
                default:   o_read_data =                                   'x ;
            endcase
        end
        // o_read_data = memory[addr_data.index][hit_index][(addr_data.offset +1) * 8 -1 -: ELEMENT_WIDTH];
        o_miss = (i_load.enable && !o_hit);
    end

    always_comb begin : state_machine
        next_state = state;
        case (state)
            D_IDLE: begin
                if (!o_hit) begin
                    if (i_load.enable) begin
                        next_state = D_L_REQUEST;
                    end else if (i_store.enable) begin
                        next_state = D_S_REQUEST;
                    end
                end
            end
            D_S_REQUEST: begin
                if (o_hit && !i_load.enable) begin
                    next_state = D_IDLE;
                end else if (!o_hit && i_load.enable) begin
                    next_state = D_BOTH_REQUEST;
                end
            end
            D_L_REQUEST: begin
                if (o_hit) begin
                    next_state = D_IDLE;
                end
            end
            D_BOTH_REQUEST: begin
                if (o_hit) begin
                    next_state = D_S_REQUEST;
                end
            end
        endcase
    end

    always_ff @( posedge clk or posedge rst) begin : control_flow
        if (rst) begin
            for (int i = 0; i < N_SECTORS; i++) begin
                for (int j = 0; j < N_LINES; j++) begin
                    valid_bit[i][j] <= 1'b0;
                    dirty_bit[i][j] <= 1'b0;
                end
            end
            state <= D_IDLE;
            o_mem_enable <= 1'b0;
            o_mem_ack <= 1'b0;
        end else begin
            o_mem_ack <= 1'b0;
            o_mem_enable <= 1'b0;
            o_mem_data <= 'x;
            state <= next_state;
            case (state)
                D_IDLE: begin
                    if (!i_load.enable && i_store.enable && !o_hit || i_load.enable && !o_hit && !i_hit) begin
                        // store or load miss
                        request_mem(0);
                    end
                    if (!i_load.enable && i_store.enable && o_hit) begin
                        store_hit();
                    end
                end
                D_S_REQUEST: begin
                    if (i_load.enable && !o_hit && !i_hit) begin
                        // load miss
                        request_mem(1);
                    end else if (!i_load.enable && o_hit) begin
                        store_hit();
                    end else begin
                        evict_dirty_try_get_mem(0, addr_store.index);
                    end
                end
                D_L_REQUEST: begin
                    evict_dirty_try_get_mem(0, addr_load.index);
                end
                D_BOTH_REQUEST: begin
                    evict_dirty_try_get_mem(1, addr_load.index);
                    get_from_mem(0, addr_store.index);
                end
            endcase
        end
    end

endmodule

