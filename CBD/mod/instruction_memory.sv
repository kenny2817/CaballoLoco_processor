
module ime 
    import const_pkg::*;
(
    input logic                         clk,
    input logic                         rst,
    input logic [IINDEX_WIDTH -1 : 0]    rnd,

    input logic [VA_WIDTH -1 : 0]       i_virtual_addr,

    output logic [REG_WIDTH -1 : 0]    o_data_loaded,
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
        .N_LINES(ITLB_LINES)
    ) TLB (
        .clk(clk),
        .rst(rst),

        .i_enable(i_write_enable),
        .i_virtual_addr(i_virtual_addr), // both write and read
        .i_physical_addr(i_physical_addr),

        .o_physical_addr(tlb_pa_addr),
        .o_miss(o_tlb_miss)
    );

    ica CACHE (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),
        
        .i_va_addr(i_virtual_addr),
        .i_pa_addr(tlb_pa_addr),

        .o_miss(o_cache_miss),
        .o_read_data(o_data_loaded),

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

