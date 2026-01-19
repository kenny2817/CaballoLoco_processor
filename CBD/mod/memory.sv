
module memory #(
    parameter PA_WIDTH      = 8,
    parameter LINE_WIDTH    = 32,
    parameter ID_WIDTH      = 4,
    parameter STAGES        = 5,
    parameter BUFFER_LENGTH = 4
) (
    input logic                         clk,
    input logic                         rst,

    // from arbiter
    input logic                         i_mem_enable,
    input logic                         i_mem_write,
    input logic [PA_WIDTH   -1 : 0]     i_mem_addr, // address of data
    input logic [LINE_WIDTH -1 : 0]     i_mem_data, // actual data
    input logic [ID_WIDTH   -1 : 0]     i_mem_id,
    input logic                         i_mem_ack,

    // to cache
    output logic                        o_mem_enable,
    output logic [LINE_WIDTH    -1 : 0] o_mem_data,
    output logic [ID_WIDTH      -1 : 0] o_mem_id_response,
    output logic                        o_mem_full //mem piena
);

    typedef struct packed {
        logic [ID_WIDTH   -1 : 0]       id;
        logic [LINE_WIDTH    -1 : 0]    data;
        logic                           valid;
    } buffer_t;

    // internal logic
    localparam int                      DEPTH = 1 << PA_WIDTH;
    
    // memory
    logic [LINE_WIDTH-1:0]              mem [DEPTH-1:0];

    // pipeline registers (valid + fields)
    logic                               valid [STAGES]; //  tracking of which pipeline elements have active/valid data
    logic [PA_WIDTH-1:0]                addr  [STAGES]; //  address memorized for each stage
    logic [LINE_WIDTH-1:0]              data  [STAGES]; //  data associated to request in each stage
    logic                               write [STAGES]; //  1 = write stage, 0 = read stage
    logic [ID_WIDTH-1:0]                id    [STAGES]; //  id associated to stage

    buffer_t                            buffer [BUFFER_LENGTH]; //results
    int                                 buffer_next = 0;
    int                                 buffer_exit = 0;

    // pipeline shift
    int                                 i;

     // output full signal
    assign o_mem_full           = buffer[buffer_next].valid && !write[STAGES-1];
    assign o_mem_enable         = buffer[buffer_exit].valid;
    assign o_mem_data           = buffer[buffer_exit].data;
    assign o_mem_id_response    = buffer[buffer_exit].id;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // initialize everything to zero
            for (i=0;i<STAGES;i=i+1) begin
                valid[i] <= 1'b0;
                addr[i]  <= '0;
                data[i]  <= '0;
                write[i] <= 1'b0;   // read
                id[i]    <= '0;
            end
            buffer_next <= 0;
            buffer_exit <= 0;
            for (int k=0; k<BUFFER_LENGTH; k++) begin
                buffer[k].valid <= 1'b0;
            end
        end else if (!o_mem_full) begin
            // shift pipeline from MSB down to 1
            for (i = STAGES -1; i > 0; i--) begin
                valid[i] <= valid[i-1];
                addr[i]  <= addr[i-1];
                data[i]  <= data[i-1];
                write[i] <= write[i-1];
                id[i]    <= id[i-1];
            end

            // accept new request into stage 0
            valid[0] <= i_mem_enable;
            addr[0]  <= i_mem_addr;
            data[0]  <= i_mem_data;
            write[0] <= i_mem_write;
            id[0]    <= i_mem_id;

            // handle MEM stage access combinationally on clock edge: perform writes and read
            if (valid[STAGES - 1] && write[STAGES - 1]) begin 
                // write to memory
                mem[addr[STAGES - 1]] <= data[STAGES - 1];
            end

            if (valid[STAGES-1] && !write[STAGES-1]) begin
                buffer[buffer_next].data    <= mem[addr[STAGES-1]];
                buffer[buffer_next].id      <= id[STAGES-1];
                buffer[buffer_next].valid   <= 1'b1;
                buffer_next <= (buffer_next + 1) % BUFFER_LENGTH;
            end

            if (buffer[buffer_exit].valid && i_mem_ack) begin
                buffer[buffer_exit].valid <= 1'b0;
                buffer_exit <= (buffer_exit + 1) % BUFFER_LENGTH;
            end
        end
    end
 
endmodule
