
typedef enum logic [1:0] { 
    IDLE,                   // ready for store and load
    S_IDLE,                 // wait mem miss, ready for load
    L_BUSY,                 // stall, wait load miss
    S_BUSY                  // stall, wait load miss, store in background
} cache_state;


module cache #(
    parameter N_SECTORS,                                    // number of sectors
    parameter N_LINES,                                      // number of lines per sector
    parameter N_ELEMENTS,                                   // number of elements per line
    parameter N_BYTES,                                      // number of bytes per element
    parameter VA_WIDTH,                                     // virtual address width
    parameter PA_WIDTH,                                     // physical address width (this should be already the tag!)
    
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
    input logic [VA_WIDTH -1 : 0]           i_va_addr,
    input logic [PA_WIDTH -1 : 0]           i_pa_addr,
    input logic [ELEMENT_WIDTH -1 : 0]      i_write_data, 

    output logic                            o_hit,
    output logic                            o_stall,
    output logic [ELEMENT_WIDTH -1 : 0]     o_read_data,

    // mem  
    output logic                            o_mem_enable,
    output logic                            o_mem_type,
    output logic                            o_mem_ack,
    output logic [PA_WIDTH -1 : 0]          o_mem_addr,
    output logic [LINE_WIDTH -1 : 0]        o_mem_data,

    input logic                             i_mem_enable,
    input logic [LINE_WIDTH -1 : 0]         i_mem_data,
    input logic [PA_WIDTH -1 : 0]           i_mem_addr
);
    localparam SECTOR_WIDTH = $clog2(N_SECTORS);
    localparam OFFSET_WIDTH = $clog2(N_ELEMENTS);

    logic [LINE_WIDTH -1 : 0]               memory          [N_SECTORS][N_LINES];
    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   tag             [N_SECTORS][N_LINES];
    logic                                   valid_bit       [N_SECTORS][N_LINES];
    logic                                   dirty_bit       [N_SECTORS][N_LINES];

    logic [SECTOR_WIDTH -1 : 0]             idx_registry    [2];
    logic [INDEX_WIDTH -1 : 0]              rnd_registry    [2];
    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   tag_registry    [2];
    logic                                   mem_idx;


    logic [PA_WIDTH -OFFSET_WIDTH -1 : 0]   addr_tag;
    logic [SECTOR_WIDTH -1 : 0]             addr_idx;
    logic [OFFSET_WIDTH -1 : 0]             addr_off;
    logic [INDEX_WIDTH -1 : 0]              hit_index;

    cache_state                             state;
    cache_state                             next_state;

    // tasks
    task automatic evict(
        input int registry_slot
    );
        o_mem_enable <= 1'b1;
        o_mem_type <= 1'b1;  // Write
        o_mem_addr <= {tag[idx_registry[registry_slot]][rnd_registry[registry_slot]], {OFFSET_WIDTH{1'b0}}};
        o_mem_data <= memory[idx_registry[registry_slot]][rnd_registry[registry_slot]];
        dirty_bit[idx_registry[registry_slot]][rnd_registry[registry_slot]] <= 1'b0;
    endtask

    task automatic load_from_mem(
        input int registry_slot
    );
        o_mem_ack <= 1'b1;
        tag         [idx_registry[registry_slot]][rnd_registry[registry_slot]] <= i_mem_addr[PA_WIDTH -1 : OFFSET_WIDTH];
        memory      [idx_registry[registry_slot]][rnd_registry[registry_slot]] <= i_mem_data;
        valid_bit   [idx_registry[registry_slot]][rnd_registry[registry_slot]] <= 1'b1;
        dirty_bit   [idx_registry[registry_slot]][rnd_registry[registry_slot]] <= 1'b0;
    endtask

    task automatic request_mem(
        input int registry_slot
    );
        o_mem_enable <= 1'b1;
        o_mem_type <= 1'b0;
        o_mem_addr <= {addr_tag, {(OFFSET_WIDTH){1'b0}}};
        tag_registry[registry_slot] <= addr_tag;
        idx_registry[registry_slot] <= addr_idx;
        rnd_registry[registry_slot] <= rnd;
    endtask

    task automatic store_hit(  
    );
        memory[addr_idx][hit_index][(addr_off +1) * ELEMENT_WIDTH -1 -: ELEMENT_WIDTH] <= i_write_data;
        dirty_bit[addr_idx][hit_index] <= 1'b1;
    endtask

    // assignments
    assign addr_tag = i_pa_addr[PA_WIDTH -1 : OFFSET_WIDTH];
    assign addr_idx = i_va_addr[SECTOR_WIDTH + OFFSET_WIDTH -1 : OFFSET_WIDTH];
    assign addr_off = i_va_addr[OFFSET_WIDTH -1 : 0];
    assign mem_idx = (tag_registry[1] == i_mem_addr[PA_WIDTH -1 : OFFSET_WIDTH]);
    
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
                            next_state = L_BUSY;
                        end else begin
                            next_state = S_IDLE;
                        end
                    end
                end
                S_IDLE: begin
                    if (o_hit && !i_is_load) begin
                        next_state = IDLE;
                    end else if (!o_hit && i_is_load) begin
                        next_state = S_BUSY;
                    end
                end
                L_BUSY: begin
                    if (o_hit && i_is_load) begin
                        next_state = IDLE;
                    end
                end
                S_BUSY: begin
                    if (o_hit && i_is_load) begin
                        next_state = S_IDLE;
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
        end else if (i_enable) begin
            state <= next_state;
            o_mem_ack <= 1'b0;
            o_mem_enable <= 1'b0;
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
                S_IDLE: begin
                    if (i_is_load && !o_hit && !i_hit) begin
                        // load miss
                        request_mem(1);
                    end else if (!i_is_load && o_hit) begin
                        store_hit();
                    end else if (dirty_bit[idx_registry[0]][rnd_registry[0]]) begin
                        // eviction - buffer accepts write in 1 cycle
                        evict(0);
                    end else if (i_mem_enable) begin
                        load_from_mem(0);
                    end
                end
                L_BUSY: begin
                    if (dirty_bit[idx_registry[0]][rnd_registry[0]]) begin
                        // eviction - buffer accepts write in 1 cycle
                        evict(0);
                    end else if (i_mem_enable) begin
                        load_from_mem(0);
                    end
                end
                S_BUSY: begin
                    if (dirty_bit[idx_registry[1]][rnd_registry[1]]) begin
                        // eviction - buffer accepts write in 1 cycle
                        evict(1);
                    end else if (dirty_bit[idx_registry[0]][rnd_registry[0]]) begin
                        // eviction - buffer accepts write in 1 cycle
                        evict(0);
                    end else if (i_mem_enable) begin
                        load_from_mem(mem_idx);
                    end
                end
            endcase
        end else begin
            o_mem_enable <= 1'b0;
            o_mem_ack <= 1'b0;
        end
    end

endmodule

