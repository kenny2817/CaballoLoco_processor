
module ime #(
    parameter TLB_LINES,
    parameter CACHE_SECTORS,
    parameter CACHE_LINES,
    parameter CACHE_BYTES,
    parameter VA_WIDTH, 
    parameter PA_WIDTH,
    parameter ID_WIDTH,
    localparam INDEX_WIDTH   = $clog2(CACHE_LINES)
) (
    input logic                         clk,
    input logic                         rst,
    input logic [INDEX_WIDTH -1 : 0]    rnd,

    input logic                         i_enable,
    input logic [VA_WIDTH -1 : 0]       i_virtual_addr,

    output logic [CACHE_BYTES*8 -1 : 0] o_data_loaded,
    output logic                        o_tlb_miss,
    output logic                        o_cache_miss,

    // tlb write
    input logic                         i_write_enable,
    input logic [PA_WIDTH -1 : 0]       i_physical_addr,

    // mem
    output logic                        o_mem_enable,
    output logic [PA_WIDTH -1 : 0]      o_mem_addr,
    output logic                        o_mem_ack,

    input logic                         i_mem_enable,
    input logic [LINE_WIDTH -1 : 0]     i_mem_data,
    input logic [ID_WIDTH -1 : 0]       i_mem_id_request,
    input logic [ID_WIDTH -1 : 0]       i_mem_id_response,
    input logic                         i_mem_in_use
);

    logic [PA_WIDTH -1 : 0]             tlb_pa_addr;

    tlb #(
        .N_LINES(TLB_LINES),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH)
    ) TLB (
        .clk(clk),
        .rst(rst),

        .i_write_enable(i_write_enable),
        .i_virtual_addr(i_virtual_addr), // both write and read
        .i_physical_addr(i_physical_addr),

        .o_physical_addr(tlb_pa_addr),
        .o_miss(o_tlb_miss)
    );

    ica #(
        .N_SECTORS(CACHE_SECTORS),
        .N_LINES(CACHE_LINES),
        .N_BYTES(CACHE_BYTES),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) CACHE (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),
        
        .i_enable(i_enable && !o_exeption),
        .i_va_addr(i_virtual_addr),
        .i_pa_addr(tlb_pa_addr),

        .o_miss(o_cache_miss),

        .o_mem_enable(o_mem_enable),
        .o_mem_addr(o_mem_addr),
        .o_mem_ack(o_mem_ack),

        .i_mem_enable(i_mem_enable),
        .i_mem_data(i_mem_data),
        .i_mem_id_request(i_mem_id_request),
        .i_mem_id_response(i_mem_id_response),
        .i_mem_in_use(i_mem_in_use)
    );

endmodule

