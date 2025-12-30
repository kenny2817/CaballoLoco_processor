
module memory #(
    parameter PA_WIDTH      = 8,
    parameter LINE_WIDTH    = 32,
    parameter ID_WIDTH      = 4,
    parameter STAGES        = 5
) (
    input logic                         clk,
    input logic                         rst,

    // from arbiter
    input logic                         i_mem_enable,
    input logic                         i_mem_write,
    input logic [PA_WIDTH   -1 : 0]     i_mem_addr, // address of data
    input logic [LINE_WIDTH -1 : 0]     i_mem_data, // actual data
    input logic [ID_WIDTH   -1 : 0]     i_mem_id,

    // to cache
    output logic                        o_mem_enable,
    output logic [LINE_WIDTH    -1 : 0] o_mem_data,
    output logic [ID_WIDTH      -1 : 0] o_mem_id_response
);

    // internal logic
    localparam int DEPTH = 1 << PA_WIDTH;
    localparam int MEM_STAGE = STAGES/2;

    // Memory access stage: choose a stage index where MEM access happens.
    // We choose stage k = 2 (middle) so we have stages before and after for updates and decodes (0 .. STAGES-1).
    
    // memory
    logic [LINE_WIDTH-1:0] mem [DEPTH-1:0];

    // local read helper
    logic [LINE_WIDTH-1:0] mem_read;
    logic [LINE_WIDTH-1:0] read_result;

    // pipeline registers (valid + fields)
    logic [STAGES-1:0]                  valid;          //  tracking of which pipeline elements have active/valid data
    logic [PA_WIDTH-1:0]                addr  [STAGES]; //  address memorized for each stage
    logic [LINE_WIDTH-1:0]              data  [STAGES]; //  data associated to request in each stage
    logic                               write [STAGES]; //  1 = write stage, 0 = read stage
    logic [ID_WIDTH-1:0]                id    [STAGES]; //  id associated to stage

    // pipeline shift
    int i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // initialize everything to zero
            valid <= '0;
            for (i=0;i<STAGES;i=i+1) begin
                addr[i]  <= '0;
                data[i]  <= '0;
                write[i] <= 1'b0;   // read
                id[i]    <= '0;
            end
            o_mem_enable <= 1'b0;
            o_mem_data   <= '0;
            o_mem_id_response <= '0;
        end else begin
            // shift pipeline from MSB down to 1
            for (i=STAGES-1; i>0; i=i-1) begin
                valid[i] <= valid[i-1];
                addr[i]  <= addr[i-1];
                data[i]  <= data[i-1];
                write[i] <= write[i-1];
                id[i]    <= id[i-1];
            end

            // accept new request into stage 0 if there is a valid input
            valid[0] <= i_mem_enable;
            addr[0]  <= i_mem_addr;
            data[0]  <= i_mem_data;
            write[0] <= i_mem_write;
            id[0]    <= i_mem_id;


            // handle MEM stage access combinationally on clock edge: perform writes and read
            if (valid[MEM_STAGE - 1] && write[MEM_STAGE - 1]) begin // valid and it is a write
                    // write to memory
                    mem[addr[MEM_STAGE - 1]] <= data[MEM_STAGE - 1];
            end

            // produce outputs from last stage (stage STAGES-1)
            if (valid[STAGES-2]) begin
                o_mem_enable <= 1'b1;
                // if the request was a read we must deliver the latest data.
                if (!write[STAGES-2]) begin
                    o_mem_data <= read_result;
                end else begin
                    // the response corresponds to a write command: optionally return written data
                    o_mem_data <= data[STAGES-2];   // it can be also returned array of zero, but that could actually 
                                                    // be the content of the memory
                end
                o_mem_id_response <= id[STAGES-2];
            end else begin
                o_mem_enable <= 1'b0;
                o_mem_data   <= '0;
                o_mem_id_response <= '0;
            end
        end
    end

     // Combinational forwarding logic: compute read_result from mem or in-flight writes
    always_comb begin
        // default: read from memory
        read_result = mem[addr[STAGES-2]];
        
        // check for more recent writes in pipeline, that is forwarding
        // by scanning from stage 0 up to STAGES-3 (all stages before the one producing output)
        for (int j = 0; j < STAGES-2; j = j + 1) begin
            if (valid[j] && write[j] && (addr[j] == addr[STAGES-2])) begin
                read_result = data[j];
                // we don't break because we want the OLDEST matching write (closest to commit)
            end
        end
        
        // also check if MEM_STAGE-1 has a matching write that's about to be committed
        if (valid[MEM_STAGE-1] && write[MEM_STAGE-1] && (addr[MEM_STAGE-1] == addr[STAGES-2])) begin
            read_result = data[MEM_STAGE-1];
        end
    end
    
endmodule
