
module dca_tb;

    // === PARAMETERS ===
    localparam N_SECTORS = 2;
    localparam N_LINES   = 2;
    localparam N_ELEMENTS = 2;
    localparam N_BYTES   = 1;
    localparam VA_WIDTH  = 8;
    localparam PA_WIDTH  = 8;
    localparam ID_WIDTH  = 2;

    localparam ELEMENT_WIDTH = N_BYTES * 8;
    localparam LINE_WIDTH    = N_ELEMENTS * ELEMENT_WIDTH;
    localparam INDEX_WIDTH   = $clog2(N_LINES);

    // === SIGNALS ===
    logic clk = 0;
    logic rst;
    logic [INDEX_WIDTH-1:0] rnd;

    logic i_hit;
    logic i_enable;
    logic i_is_load;
    logic [VA_WIDTH-1:0] i_va_load, i_va_store;
    logic [PA_WIDTH-1:0] i_pa_load, i_pa_store;
    logic [ELEMENT_WIDTH-1:0] i_data_store;

    logic o_hit;
    logic o_stall;
    logic [ELEMENT_WIDTH-1:0] o_read_data;

    // memory interface
    logic o_mem_enable;
    logic [PA_WIDTH-1:0] o_mem_addr;
    logic [LINE_WIDTH-1:0] o_mem_data;
    logic o_mem_type;
    logic o_mem_ack;

    logic i_mem_enable;
    logic [LINE_WIDTH-1:0] i_mem_data;
    logic [ID_WIDTH-1:0] i_mem_id_request;
    logic [ID_WIDTH-1:0] i_mem_id_response;

    // === DUT ===
    dca #(
        .N_SECTORS(N_SECTORS),
        .N_LINES(N_LINES),
        .N_ELEMENTS(N_ELEMENTS),
        .N_BYTES(N_BYTES),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),

        .i_hit(i_hit),
        .i_enable(i_enable),
        .i_is_load(i_is_load),
        .i_va_load(i_va_load),
        .i_pa_load(i_pa_load),
        .i_va_store(i_va_store),
        .i_pa_store(i_pa_store),
        .i_data_store(i_data_store),

        .o_hit(o_hit),
        .o_stall(o_stall),
        .o_read_data(o_read_data),

        .o_mem_enable(o_mem_enable),
        .o_mem_addr(o_mem_addr),
        .o_mem_data(o_mem_data),
        .o_mem_type(o_mem_type),
        .o_mem_ack(o_mem_ack),

        .i_mem_enable(i_mem_enable),
        .i_mem_data(i_mem_data),
        .i_mem_id_request(i_mem_id_request),
        .i_mem_id_response(i_mem_id_response)
    );

    // === CLOCK ===
    always #5 clk = ~clk;

    // === PRINTING ===
    task automatic print_cache(string title);
        $display("=== %s ===", title);
        for (int i = 0; i < N_SECTORS; i++) begin
            for (int j = 0; j < N_LINES; j++) begin
                $display("| sec %0d line %0d | tag=%h | data=%h | valid=%b | dirty=%b |",
                    i, j, dut.tag[i][j], dut.memory[i][j], dut.valid_bit[i][j], dut.dirty_bit[i][j]);
            end
        end
        $display("state=%0d | mem_en=%b | mem_type=%b | mem_ack=%b | hit=%b | stall=%b",
                 dut.state, o_mem_enable, o_mem_type, o_mem_ack, o_hit, o_stall);
        $display("---------------------------------------------------\n");
    endtask

    // === TEST SEQUENCE ===
    initial begin
        $monitoroff;
        // Reset
        rst = 1; #10; rst = 0;
        rnd = 0;
        i_enable = 0;
        i_is_load = 0;
        i_hit = 0;
        i_mem_enable = 0;
        i_mem_id_request = 0;
        i_mem_id_response = 0;
        i_mem_data = '0;
        #10;
        $monitoron;

        // --- Test 1: Load miss (expect memory request) ---
            $display("[TEST 1] Load miss");
            i_enable = 1;
            i_is_load = 1;
            i_va_load = 8'h00;
            i_pa_load = 8'h00;
            #10; i_mem_id_request = 1;
            print_cache("After load miss request");

            // Simulate memory response
            i_mem_enable = 1;
            i_mem_data = 16'hAAAA;
            #10; 
            if (o_mem_ack) i_mem_enable = 0;
            #10;
            i_mem_id_response = 1;
            print_cache("After memory load response");

        // --- Test 2: Load hit (expect immediate read) ---
            $display("[TEST 2] Load hit");
            #10;
            print_cache("After load hit");

        // --- Test 3: Store miss (expect write mem request) ---
            $display("[TEST 3] Store miss");
            i_is_load = 0;
            i_va_store = 8'h02;
            i_pa_store = 8'h02;
            i_data_store = 8'hBB;
            #10;
            print_cache("After store miss request");

            // Simulate memory response
            i_mem_enable = 1;
            i_mem_id_response = 1;
            i_mem_data = 16'h0000;
            #10; 
            if (o_mem_ack) i_mem_enable = 0;
            #10;
            print_cache("After store hit update");

        // --- Test 4: BOTH_REQUEST (load + store same cycle) ---
        $display("[TEST 4] BOTH_REQUEST");
        i_is_load = 0;
        i_va_store = 8'h30;
        i_pa_store = 8'h30;
        i_data_store = 8'hEE;
        #10;
        i_is_load = 1;
        i_va_load = 8'h40;
        i_pa_load = 8'h40;
        #10;
        print_cache("After BOTH_REQUEST interaction");

        // so much needs to be tested here...TODO

        #1; $finish;
    end

    // === MONITOR ===
    // initial $monitor("t=%0t | en=%b is_load=%b | hit=%b | stall=%b | mem_en=%b type=%b | addr=%h | data=%h | state=%0d",
    //     $time, i_enable, i_is_load, o_hit, o_stall, o_mem_enable, o_mem_type, o_mem_addr, o_mem_data, dut.state);

endmodule
