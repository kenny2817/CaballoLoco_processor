
module arb_tb;

    // Parameters
    localparam PA_WIDTH   = 8;
    localparam LINE_WIDTH = 16;
    localparam ID_WIDTH   = 3;
    localparam N_LINES    = 2;

    // Clock
    logic clk = 0;
    always #5 clk = ~clk;

    // DUT I/O
    logic rst;

    // Instruction interface
    logic i_instr_enable;
    logic [PA_WIDTH-1:0] i_instr_addr;

    // Data interface
    logic i_data_enable;
    logic [PA_WIDTH-1:0] i_data_addr;
    logic [LINE_WIDTH-1:0] i_data;
    logic i_data_write;

    // Handshake
    logic i_ack;

    // Outputs
    logic o_enable;
    logic [ID_WIDTH-1:0] o_id_request;
    logic [ID_WIDTH-1:0] o_id_response;
    logic [LINE_WIDTH-1:0] o_data;
    logic o_stall;

    // Memory side
    logic i_mem_enable;
    logic [ID_WIDTH-1:0] i_mem_id;
    logic [LINE_WIDTH-1:0] i_mem_data;
    logic i_mem_ack;

    logic o_mem_ack;
    logic [PA_WIDTH-1:0] o_mem_addr;
    logic o_mem_data;
    logic o_mem_enable;
    logic o_mem_write;
    logic o_mem_id;

    // DUT instantiation
    arb #(
        .PA_WIDTH(PA_WIDTH),
        .LINE_WIDTH(LINE_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .N_LINES(N_LINES)
    ) dut (
        .clk(clk),
        .rst(rst),

        .i_instr_enable(i_instr_enable),
        .i_instr_addr(i_instr_addr),

        .i_data_enable(i_data_enable),
        .i_data_addr(i_data_addr),
        .i_data(i_data),
        .i_data_write(i_data_write),

        .i_ack(i_ack),

        .o_enable(o_enable),
        .o_id_request(o_id_request),
        .o_id_response(o_id_response),
        .o_data(o_data),
        .o_stall(o_stall),

        .i_mem_enable(i_mem_enable),
        .i_mem_id(i_mem_id),
        .i_mem_data(i_mem_data),
        .i_mem_ack(i_mem_ack),

        .o_mem_ack(o_mem_ack),
        .o_mem_addr(o_mem_addr),
        .o_mem_data(o_mem_data),
        .o_mem_enable(o_mem_enable),
        .o_mem_write(o_mem_write),
        .o_mem_id(o_mem_id)
    );

    // Helper task
    task automatic print_state(string label);
        $display("=== %s ===", label);
        for (int i = 0; i < N_LINES; i++) begin
            $display("| Line %0d | valid=%b | write=%b | id=%0d | addr=%h | data=%h |",
                i, dut.is_valid[i], dut.is_write[i], dut.id[i], dut.address[i], dut.data[i]);
        end
        $display("oldest=%0d newest=%0d id_counter=%0d stall=%b", 
            dut.oldest_line, dut.newest_line, dut.id_counter, o_stall);
        $display("___________________________________________________________\n");
    endtask

    // Test sequence
    initial begin
        $monitoroff;
        // Reset
        rst = 1;
        i_instr_enable = 0;
        i_data_enable  = 0;
        i_ack = 0;
        i_mem_enable = 0;
        i_mem_ack = 0;
        #10; 
        rst = 0;
        $monitoron;

        // --- Test 1: read ---
        $display("[TEST 1] request");
        i_instr_enable = 1;
        i_instr_addr   = 8'h01;
        #10; 
        i_instr_enable = 0;
        i_data_enable = 1;
        i_data_addr = 8'h02;
        i_data = 16'hAAAA;
        i_data_write = 1;
        #10; i_data_enable = 0;
        #10;
        print_state("After 2 read requests (expect stall=0)");

        // --- Test 2: Data write ---
        $display("[TEST 2] stall if full");
        i_data_enable = 1;
        i_data_addr = 8'h03;
        i_data = 16'hBBBB;
        i_data_write = 0;
        #10;
        print_state("After data write request (expect stall=1)");

        // --- Test 3: Memory ack (free oldest line) ---
        $display("[TEST 3] Memory ack frees oldest");
        i_mem_ack = 1;
        #10; i_mem_ack = 0; 
        #10; i_data_enable = 0;
        #10;
        print_state("After memory ack (expect stall=0)");

        // --- Test 4: FIFO full / stall ---
        $display("[TEST 4] concurrency instruction data");
        i_mem_ack = 1;
        #10; i_mem_ack = 0; 
        i_instr_enable = 1; i_data_enable = 1;
        i_instr_addr = 8'h04; i_data_addr = 8'h04;
        i_data_write = 1; i_data = 16'hCCCC;
        #10; i_instr_enable = 0; i_data_enable = 0;
        #10;
        print_state("only the data should have been taken (expect stall=0)");

        #1; $finish;
    end

    initial $monitor("t=%0t | instr_en=%b data_en=%b mem_en=%b mem_ack=%b stall=%b mem_req=%b id=%0d",
        $time, i_instr_enable, i_data_enable, o_mem_enable, i_mem_ack, o_stall, o_mem_enable, o_id_request);

endmodule
