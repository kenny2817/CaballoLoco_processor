
module memory #(
    parameter PA_WIDTH,
    parameter LINE_WIDTH,
    parameter ID_WIDTH
) (
    input logic                         clk,
    input logic                         rst,

    // from arbiter
    input logic                         i_mem_enable,
    input logic                         i_mem_write,
    input logic [PA_WIDTH -1 : 0]       i_mem_addr,
    input logic [LINE_WIDTH -1 : 0]     i_mem_data,
    input logic [ID_WIDTH -1 : 0]       i_mem_id,

    // to cache
    output logic                        o_mem_enable,
    output logic [LINE_WIDTH -1 : 0]    o_mem_data,
    output logic [ID_WIDTH -1 : 0]      o_mem_id_response
);

    // internal logic
    
endmodule