
module dca #(
    parameter TLB_LINES,
    parameter CACHE_SECTORS,
    parameter CACHE_LINES,
    parameter CACHE_ELEMENTS,
    parameter STB_LINES,
    parameter REG_WIDTH, 
    parameter VA_WIDTH, 
    parameter PA_WIDTH,
    localparam INDEX_WIDTH   = $clog2(CACHE_LINES)
) (
    input logic                         clk,
    input logic                         rst,
    input logic [INDEX_WIDTH -1 : 0]    rnd,

    input logic                         i_is_load,
    input logic                         i_is_store,
    input logic [VA_WIDTH -1 : 0]       i_virtual_addr,
    input logic [REG_WIDTH -1 : 0]      i_write_data,

    output logic                        o_data_loaded,
    output logic                        o_exeption,
    output logic                        o_stall
);

    localparam CACHE_BYTES = REG_WIDTH / 8;

    // tlb
    logic [PA_WIDTH -1 : 0]             tlb_pa_addr;

    // stb
    logic                               stb_valid_commit;
    logic [REG_WIDTH -1 : 0]            stb_data_commit;
    logic [VA_WIDTH -1 : 0]             stb_addr_commit;
    logic                               stb_stall;
    logic                               stb_hit;
    logic [REG_WIDTH -1 : 0]            stb_data;

    // cache
    logic                               cache_hit;
    logic                               cache_stall;
    logic [REG_WIDTH -1 : 0]            cache_data;

    // logic
    logic                               enable;
    logic [VA_WIDTH -1 : 0]             virtual_addr;

    assign o_data_loaded = stb_hit ? stb_data : cache_data;
    assign o_stall = stb_stall || cache_stall;
    assign enable = o_exeption && (i_is_load || stb_valid_commit);
    assign virtual_addr = i_is_load ? i_virtual_addr : stb_addr_commit;

    tlb #(
        .N_LINES(TLB_LINES),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH)
    ) TLB (
        .clk(clk),
        .rst(rst),

        .i_write_enable(),
        .i_write_virtual_addr(),
        .i_write_physical_addr(),

        .i_virtual_addr(virtual_addr),

        .o_physical_addr(tlb_pa_addr),
        .o_exeption(o_exeption)
    );

    stb #(
        .VA_WIDTH(VA_WIDTH),
        .N_LINES(STB_LINES)
    ) STB (
        .clk(clk),
        .rst(rst),
        
        .i_is_store(i_is_store),
        .i_adress(i_virtual_addr),
        .i_write_data(i_write_data),

        .i_load_cache(i_is_load),
        .i_hit_cache(cache_hit),

        .o_valid_commit(stb_valid_commit),
        .o_data_commit(stb_data_commit),
        .o_addr_commit(stb_addr_commit),

        .o_stall(stb_stall),

        .o_hit(stb_hit),
        .o_read_data(stb_data)
    );

    cache #(
        .N_SECTORS(CACHE_SECTORS),
        .N_LINES(CACHE_LINES),
        .N_ELEMENTS(CACHE_ELEMENTS),
        .N_BYTES(CACHE_BYTES),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH)
    ) CACHE (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),
        
        .i_hit(stb_hit),
        .i_enable(enable),
        .i_is_load(i_is_load),
        .i_va_addr(virtual_addr),
        .i_pa_addr(tlb_pa_addr),
        .i_write_data(stb_data_commit),

        .o_hit(cache_hit),
        .o_stall(cache_stall),
        .o_read_data(cache_data),

        .o_mem_enable(),
        .o_mem_type(),
        .o_mem_ack(),
        .o_mem_addr(),
        .o_mem_data(),

        .i_mem_enable(),
        .i_mem_data(),
        .i_mem_addr()

    );

endmodule

