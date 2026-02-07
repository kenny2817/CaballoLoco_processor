
module dme 
    import const_pkg::*;
    import cable_pkg::*;
(
    input logic                         clk,
    input logic                         rst,
    input logic [INDEX_WIDTH  -1 : 0]   rnd,
 
    input mem_control_t                 i_control,
    input logic [VA_WIDTH     -1 : 0]   i_virtual_addr,
    input logic [REG_WIDTH    -1 : 0]   i_write_data,
 
    output logic [REG_WIDTH   -1 : 0]   o_data_loaded,
    output logic                        o_tlb_miss,
    output logic                        o_cache_miss,
    output logic                        o_stb_full,
 
    // tlb write 
    input logic                         i_write_enable,
    input logic [PA_WIDTH     -1 : 0]   i_physical_addr,

    // memory
    output logic                        o_mem_enable,
    output logic [PA_WIDTH    -1 : 0]   o_mem_addr,
    output logic [DLINE_WIDTH -1 : 0]   o_mem_data,
    output logic                        o_mem_write,
    output logic                        o_mem_ack,

    input logic                         i_mem_enable,
    input logic [DLINE_WIDTH  -1 : 0]   i_mem_data,
    input logic [ID_WIDTH     -1 : 0]   i_mem_id_request,
    input logic [ID_WIDTH     -1 : 0]   i_mem_id_response
);

    mem_data_t                          load_commit;
    mem_data_t                          store_commit;

    // tlb
    logic [PA_WIDTH -1 : 0]             tlb_pa_addr;

    // stb
    mem_data_t                          stb_commit;
    logic                               stb_hit;
    logic [REG_WIDTH -1 : 0]            stb_data;

    // cache
    logic                               cache_hit;
    logic [REG_WIDTH -1 : 0]            cache_data;

    // logic
    logic                               enable;

    assign load_commit  = {!o_tlb_miss && i_control.is_load, i_control.size, i_virtual_addr, {(REG_WIDTH){1'b0}}, i_control.use_unsigned};
    assign store_commit = {              i_control.is_store, i_control.size, i_virtual_addr,        i_write_data,                     'x};

    assign o_data_loaded = stb_hit ? stb_data : cache_data;

    tlb #(
        .N_LINES(DTLB_LINES)
    ) TLB (
        .clk(clk),
        .rst(rst),

        .i_enable(i_write_enable),
        .i_virtual_addr(i_virtual_addr), // both write and read
        .i_physical_addr(i_physical_addr),

        .o_physical_addr(tlb_pa_addr),
        .o_miss(o_tlb_miss)
    );

    stb STB (
        .clk(clk),
        .rst(rst),
        
        .i_store(store_commit),

        .i_load_cache(i_control.is_load),
        .i_hit_cache(cache_hit),

        .o_full(o_stb_full),

        .o_commit(stb_commit),

        .o_hit(stb_hit),
        .o_read_data(stb_data)
    );

    dca CACHE (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),
        
        .i_hit(stb_hit),
        .i_pa(tlb_pa_addr),
        .i_load(load_commit),
        .i_store(stb_commit),

        .o_hit(cache_hit),
        .o_miss(o_cache_miss),
        .o_read_data(cache_data),
        
        .o_mem_enable(o_mem_enable),
        .o_mem_addr(o_mem_addr),
        .o_mem_data(o_mem_data),
        .o_mem_type(o_mem_write),
        .o_mem_ack(o_mem_ack),

        .i_mem_enable(i_mem_enable),
        .i_mem_data(i_mem_data),
        .i_mem_id_request(i_mem_id_request),
        .i_mem_id_response(i_mem_id_response)
    );

endmodule

