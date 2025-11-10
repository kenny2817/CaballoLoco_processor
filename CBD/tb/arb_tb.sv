module arb_tb;

    // Parameters
    localparam PA_WIDTH   = 32;
    localparam LINE_WIDTH = 64;
    localparam ID_WIDTH   = 4;

    // DUT inputs
    logic clk;
    logic rst;
    logic i_instr_enable;
    logic [PA_WIDTH-1:0] i_instr_addr;
    logic i_data_enable;
    logic [PA_WIDTH-1:0] i_data_addr;
    logic [LINE_WIDTH-1:0] i_data;
    logic i_data_write;

    // DUT outputs
    logic [PA_WIDTH-1:0] o_mem_addr;
    logic o_mem_data;
    logic o_mem_enable;
    logic o_mem_write;
    logic [ID_WIDTH-1:0] o_mem_id;

    // Instantiate DUT
    arb #(
        .PA_WIDTH(PA_WIDTH),
        .LINE_WIDTH(LINE_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .i_instr_enable(i_instr_enable),
        .i_instr_addr(i_instr_addr),
        .i_data_enable(i_data_enable),
        .i_data_addr(i_data_addr),
        .i_data(i_data),
        .i_data_write(i_data_write),
        .o_mem_addr(o_mem_addr),
        .o_mem_data(o_mem_data),
        .o_mem_enable(o_mem_enable),
        .o_mem_write(o_mem_write),
        .o_mem_id(o_mem_id)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        i_instr_enable = 0;
        i_data_enable  = 0;
        i_data_write   = 0;
        i_instr_addr   = '0;
        i_data_addr    = '0;
        i_data         = '0;

        // Reset pulse
        #15 rst = 0;

        // Test 1: Instruction request
        @(posedge clk);
        i_instr_enable = 1;
        i_instr_addr   = 32'h1000;
        @(posedge clk);
        i_instr_enable = 0;

        // Test 2: Data read request
        repeat (2) @(posedge clk);
        i_data_enable  = 1;
        i_data_addr    = 32'h2000;
        i_data_write   = 0;
        @(posedge clk);
        i_data_enable  = 0;

        // Test 3: Data write request
        repeat (2) @(posedge clk);
        i_data_enable  = 1;
        i_data_addr    = 32'h3000;
        i_data         = 64'hDEADBEEFCAFEBABE;
        i_data_write   = 1;
        @(posedge clk);
        i_data_enable  = 0;

        // Test 4: Simultaneous instruction + data request
        repeat (2) @(posedge clk);
        i_instr_enable = 1;
        i_data_enable  = 1;
        i_instr_addr   = 32'h4000;
        i_data_addr    = 32'h5000;
        i_data         = 64'h123456789ABCDEF0;
        i_data_write   = 0;
        @(posedge clk);
        i_instr_enable = 0;
        i_data_enable  = 0;

        // Finish
        repeat (5) @(posedge clk);
        $finish;
    end

    // Monitor
    initial begin
        $display("Time | Enable | Write | Addr     | ID ");
        $monitor("%4t | %b      | %b     | %h | %0d",
            $time, o_mem_enable, o_mem_write, o_mem_addr, o_mem_id);
    end

endmodule
