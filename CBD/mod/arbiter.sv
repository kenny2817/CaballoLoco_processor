
module arb #(
    parameter PA_WIDTH,
    parameter LINE_BYTES,
    parameter ID_WIDTH
) (
    input logic                         clk,
    input logic                         rst,
    
    // intruction
    input logic                         i_instr_enable,     // enable instruction request
    input logic [PA_WIDTH -1 : 0]       i_instr_addr,       // instruction address

    // data
    input logic                         i_data_enable,      // enable data request
    input logic [PA_WIDTH -1 : 0]       i_data_addr,        // data address
    input logic [LINE_BYTES*8 -1 : 0]   i_data,             // write data
    input logic                         i_data_write,       // write bit

    // memory
    output logic [PA_WIDTH -1 : 0]      o_mem_addr,         // request address
    output logic [LINE_BYTES*8 -1 : 0]  o_mem_data,         // request data
    output logic                        o_mem_enable,       // enable memory request
    output logic                        o_mem_write,        // write bit
    output logic [ID_WIDTH -1 : 0]      o_mem_id            // request id
);
    // internal logic
    logic [ID_WIDTH -1 : 0]             id_counter;

    // memory request
    assign o_mem_enable     = i_instr_enable || i_data_enable;
    assign o_mem_id         = id_counter;
    assign o_mem_addr       = i_data_enable ? i_data_addr : i_instr_addr;
    assign o_mem_data       = i_data;
    assign o_mem_write      = i_data_write;

    always_ff @( posedge clk or posedge rst ) begin : clk_logic
        if (rst) begin
            id_counter  <= '0;
        end else if (o_mem_enable) begin
            id_counter <= id_counter + 1'b1;
        end
    end
    
endmodule
