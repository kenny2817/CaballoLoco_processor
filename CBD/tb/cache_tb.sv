
module cache_tb; 
    // Parameters
    localparam N_SECTORS = 2;
    localparam N_LINES = 2;
    localparam N_ELEMENTS = 2;
    localparam N_BYTES = 4;
    localparam VA_WIDTH = 8;
    localparam PA_WIDTH = 8;

    localparam ELEMENT_WIDTH = N_BYTES * 8;                 // element width in bits
    localparam LINE_WIDTH    = N_ELEMENTS * ELEMENT_WIDTH;  // line width in bits
    localparam INDEX_WIDTH   = $clog2(N_LINES);             // index width in bits

    // Testbench signals
    logic clk = 0, rst;
    logic [INDEX_WIDTH -1 : 0] rnd;
    logic is_load, is_store;
    logic [VA_WIDTH -1 : 0] va_addr;
    logic [PA_WIDTH -1 : 0] pa_addr;
    logic [ELEMENT_WIDTH -1 : 0] write_data;
    logic hit, stall;
    logic [ELEMENT_WIDTH -1 : 0] read_data;
    logic mem_enable_in, mem_enable_out, mem_type, mem_ack;
    logic [PA_WIDTH -1 : 0] mem_addr_in;
    logic [PA_WIDTH -1 : 0] mem_addr_out;
    logic [LINE_WIDTH -1 : 0] mem_data_in;
    logic [LINE_WIDTH -1 : 0] mem_data_out;



    // Instantiate the cache module
    cache # (
        .N_SECTORS(N_SECTORS),
        .N_LINES(N_LINES),
        .N_ELEMENTS(N_ELEMENTS),
        .N_BYTES(N_BYTES),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),

        .i_is_load(is_load),
        .i_is_store(is_store),
        .i_va_addr(va_addr),
        .i_pa_addr(pa_addr),
        .i_write_data(write_data),
        
        .o_hit(hit),
        .o_stall(stall),
        .o_read_data(read_data),
        
        // Mem
        .o_mem_enable(mem_enable_out),
        .o_mem_type(mem_type),
        .o_mem_ack(mem_ack),
        .o_mem_addr(mem_addr_out),
        .o_mem_data(mem_data_out),
        
        .i_mem_enable(mem_enable_in),
        .i_mem_data(mem_data_in),
        .i_mem_addr(mem_addr_in)
    );

    task automatic printing();
        $display("mem");
        for (int i = 0; i < N_SECTORS; i++) begin
            for (int j = 0; j < N_LINES; j++) begin
                $display("%h - %h | %b %b", dut.tag[i][j], dut.memory[i][j], dut.valid_bit[i][j], dut.dirty_bit[i][j]);
            end
        end
        $display("___________________________");
    endtask //automatic

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $monitoroff;
        rst = 1; is_load = 0; is_store = 0; va_addr = 0; pa_addr = 0; write_data = 0; rnd = $random; mem_enable_in = 0; mem_data_in = 0; #10;
        rst = 0; #10;

        // Initialize a cache line directly for testing hit logic
        dut.tag[0][0] = 8'h07; // Assuming PA_WIDTH is 8, and OFFSET_WIDTH is 1 (for N_ELEMENTS=2)
        dut.valid_bit[0][0] = 1'b1;
        dut.memory[0][0] = {32'hAAAAAAAA, 32'hBBBBBBBB}; // Example line data
        printing();
        $monitoron;

        is_load = 1;    va_addr = 8'h01; pa_addr = 8'h0F; #10; // Load hit
        is_load = 1;    va_addr = 8'h00; pa_addr = 8'h0F; #10; // Load hit

        is_load = 1;    va_addr = 8'h03; pa_addr = 8'h05; #30; // Load miss
        mem_enable_in = 1; mem_data_in = {32'hCCCCCCCC, 32'hDDDDDDDD}; mem_addr_in = 8'h05; #10; // Write to memory
        if (mem_ack) mem_enable_in = 0; #10;
        if (hit) is_load = 0; #10;
        printing();

        is_store = 1;   va_addr = 8'h00; pa_addr = 8'h0F; write_data = 32'h11111111; #10; // Store hit
        if (hit) is_store = 0; #10;
        printing();

        is_load = 1;    va_addr = 8'h01; pa_addr = 8'hA0; #30; // Load miss (different sector/tag)
        mem_enable_in = 1; mem_data_in = {32'h22222222, 32'h33333333}; mem_addr_in = 8'hA0; #10; // Write to memory
        if (mem_ack) mem_enable_in = 0; #10;
        if (hit) is_load = 0; #10;
        printing();
        
        is_store = 1;   va_addr = 8'h00; pa_addr = 8'hA4; write_data = 32'h55555555;#10; // Store miss
        is_store = 0; #20;
        is_load = 1;    va_addr = 8'h03; pa_addr = 8'hB0; #20; // Load miss
        mem_enable_in = 1; mem_data_in = {32'h44444444, 32'h44444444}; mem_addr_in = 8'hA4; #10; // Write to memory
        if (mem_ack) mem_enable_in = 0; #10;
        mem_enable_in = 1; mem_data_in = {32'h44444444, 32'h44444444}; mem_addr_in = 8'hB0; #10; // Write to memory
        if (mem_ack) mem_enable_in = 0; #10;
        if (hit) begin
            is_load = 0;
            is_store = 1;
        end #10;
        printing();
        #30;
        printing();
        #10;
        $finish;
    end

    initial $monitor(
        "t: %3t | s:%1d | is_load: %b | is_store: %b | va_addr: %h | pa_addr: %h | hit: %b | stall: %b | read_data: %h | mem_enable: %b | mem_type: %b | mem_ack: %b | mem_addr: %h | mem_data: %h |",
        $time, dut.state, is_load, is_store, va_addr, pa_addr, hit, stall, read_data, mem_enable_out, mem_type, mem_ack, mem_addr_out, mem_data_out
    );


endmodule
