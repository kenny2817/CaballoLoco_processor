
module arb #(
    parameter PA_WIDTH,
    parameter LINE_WIDTH,
    parameter ID_WIDTH,
    parameter N_LINES
) (
    input logic                         clk,
    input logic                         rst,
    
    // intruction
    input logic                         i_instr_enable,     // enable instruction request
    input logic [PA_WIDTH -1 : 0]       i_instr_addr,       // instruction address

    // data
    input logic                         i_data_enable,      // enable data request
    input logic [PA_WIDTH -1 : 0]       i_data_addr,        // data address
    input logic [LINE_WIDTH -1 : 0]     i_data,             // write data
    input logic                         i_data_write,       // write bit

    // handshakes
    input logic                         i_ack,              // ack response

    output logic                        o_enable,           // enable memory response
    output logic [ID_WIDTH -1 : 0]      o_id_request,       // request id
    output logic [ID_WIDTH -1 : 0]      o_id_response,      // response id
    output logic [LINE_WIDTH -1 : 0]    o_data,             // response data to write

    // logic
    output logic                        o_stall,            // stall

    // memory
    input logic                         i_mem_enable,       // enable memory response
    input logic [ID_WIDTH -1 : 0]       i_mem_id,           // response id
    input logic [LINE_WIDTH -1 : 0]     i_mem_data,         // response data
    input logic                         i_mem_ack,          // ack memory request

    output logic                        o_mem_ack,          // ack memory response
    output logic [PA_WIDTH -1 : 0]      o_mem_addr,         // request address
    output logic                        o_mem_data,         // request data
    output logic                        o_mem_enable,       // enable memory request
    output logic                        o_mem_write,        // write bit
    output logic                        o_mem_id            // request id
);
    localparam LINE_SELECT = $clog2(N_LINES);

    // internal memory
    logic [PA_WIDTH -1 : 0]             address     [N_LINES];
    logic [LINE_WIDTH -1 : 0]           data        [N_LINES]; // could be expensive
    logic                               is_valid    [N_LINES];
    logic                               is_write    [N_LINES];
    logic [ID_WIDTH -1 : 0]             id          [N_LINES];

    // internal logic
    logic [ID_WIDTH -1 : 0]             id_counter;
    logic [LINE_SELECT -1 : 0]          oldest_line;
    logic [LINE_SELECT -1 : 0]          newest_line;

    // full exeption
    assign o_stall = (i_instr_enable || i_data_enable) && is_valid[newest_line]; 
    
    // cache request
    assign o_id_request     = id_counter;

    // memory response
    assign o_enable         = i_mem_enable;
    assign o_id_response    = i_mem_id;
    assign o_data           = i_mem_data;
    assign o_mem_ack        = i_ack;

    // memory request
    assign o_mem_enable     = is_valid  [oldest_line];
    assign o_mem_id         = id        [oldest_line];
    assign o_mem_addr       = address   [oldest_line];
    assign o_mem_data       = data      [oldest_line];
    assign o_mem_write      = is_write  [oldest_line];

    // clk_logic
    always_ff @( posedge clk or posedge rst ) begin : clk_logic
        if (rst) begin
            for (int i = 0; i < N_LINES; i++) begin
                is_valid[i] <= 1'b0;
            end
            id_counter  <= '0;
            oldest_line <= '0;
            newest_line <= '0;
        end else begin
            // new_request
            if ((i_instr_enable || i_data_enable) && !is_valid[newest_line]) begin : new_request
                address [newest_line] <= i_data_enable ? i_data_addr : i_instr_addr;
                data    [newest_line] <= i_data;
                is_write[newest_line] <= i_data_enable ? i_data_write : 1'b0;
                is_valid[newest_line] <= 1'b1;
                id      [newest_line] <= id_counter;

                id_counter            <= id_counter + 1'b1;
                newest_line           <= newest_line + 1'b1;
            end
            // request_validated
            if (i_mem_ack) begin : request_validated
                is_valid[oldest_line] <= 1'b0;
                oldest_line           <= oldest_line + 1'b1;
            end
        end
    end
    
endmodule