
module cache_tb; 
    // Parameters
    localparam REG_WIDTH = 32;
    localparam N_SECTORS = 4;
    localparam N_LINES = 2;
    localparam N_ELEMENTS = 2;
    localparam N_BYTES = 4;
    localparam VA_WIDTH = 8;
    localparam PA_WIDTH = 8;

    localparam ELEMENT_WIDTH = N_BYTES * 8;                 // element width in bits
    localparam LINE_WIDTH    = N_ELEMENTS * ELEMENT_WIDTH;  // line width in bits
    localparam INDEX_WIDTH   = $clog2(N_LINES);             // index width in bits

    // Testbench signals
    logic clk = 0;
    logic rst;
    logic [INDEX_WIDTH -1 : 0] rnd;
    logic is_load;
    logic is_store;
    logic [VA_WIDTH -1 : 0] va_addr;
    logic [PA_WIDTH -1 : 0] pa_addr;
    logic [ELEMENT_WIDTH -1 : 0] write_data;
    logic hit;
    logic stall;
    logic [ELEMENT_WIDTH -1 : 0] read_data;
    logic exeption;
    logic mem_enable;
    logic mem_type;
    logic mem_ack;
    logic [PA_WIDTH -1 : 0] mem_addr;
    logic [LINE_WIDTH -1 : 0] mem_data;



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
        .o_mem_enable(mem_enable),
        .o_mem_type(mem_type),
        .o_mem_ack(mem_ack),
        .o_mem_addr(mem_addr),
        .o_mem_data(mem_data),
        
        .i_mem_enable(mem_enable),
        .i_mem_data(mem_data),
        .i_mem_addr(mem_addr)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        rst = 1; is_load = 0; is_store = 0; va_addr = 0; pa_addr = 0; write_data = 0; rnd = 0; #10;
        rst = 0; #10;

        // Initialize a cache line directly for testing hit logic
        dut.tag[0][0] = 8'hA; // Assuming PA_WIDTH is 8, and OFFSET_WIDTH is 1 (for N_ELEMENTS=2)
        dut.valid_bit[0][0] = 1'b1;
        dut.memory[0][0] = {32'hFF00FF00, 32'h00FF00FF}; // Example line data

        is_store = 1; va_addr = 8'h00; pa_addr = 8'hA0; write_data = 32'hDEADBEEF; #10; // Store hit
        is_load = 1; va_addr = 8'ha0; pa_addr = 8'hA0; #10; // Load miss (different sector/tag)
        is_load = 1; va_addr = 8'h10; pa_addr = 8'hB0; #10; // Load miss (different sector/tag)
        is_store = 1; va_addr = 8'h04; pa_addr = 8'hA4; write_data = 32'hCAFEBABE;#10; // Store hit (different offset)
        is_load = 1; va_addr = 8'h04; pa_addr = 8'hA4; #10; // Load hit
        $finish;
    end

    initial $monitor("t: %3t | is_load: %b | is_store: %b | va_addr: %h | pa_addr: %h | write_data: %h | hit: %b | stall: %b | read_data: %h | mem_enable: %b | mem_type: %b | mem_addr: %h | mem_data: %h | dut.tag[0][0]: %h | dut.valid_bit[0][0]: %b | dut.memory[0][0]: %h",
                     $time, is_load, is_store, va_addr, pa_addr, write_data, hit, stall, read_data, mem_enable, mem_type, mem_addr, mem_data, dut.tag[0][0], dut.valid_bit[0][0], dut.memory[0][0]);


endmodule
