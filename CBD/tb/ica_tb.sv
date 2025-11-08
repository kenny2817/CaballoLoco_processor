module ica_tb;

    localparam N_SECTORS = 2;
    localparam N_LINES = 2;
    localparam N_ELEMENTS = 2;
    localparam N_BYTES = 1;
    localparam VA_WIDTH = 8;
    localparam PA_WIDTH = 8;
    localparam ID_WIDTH = 2;

    localparam ELEMENT_WIDTH = N_BYTES * 8;                 // element width in bits
    localparam LINE_WIDTH    = N_ELEMENTS * ELEMENT_WIDTH;  // line width in bits
    localparam INDEX_WIDTH   = $clog2(N_LINES);             // index width in bits

    logic                           clk = 0;
    logic                           rst;
    logic [INDEX_WIDTH -1 : 0]      rnd;

    logic                           enable;
    logic [VA_WIDTH -1 : 0]         va_addr;
    logic [PA_WIDTH -1 : 0]         pa_addr;

    logic                           stall;
    logic [ELEMENT_WIDTH -1 : 0]    read_data;

    logic                           mem_enable_request;
    logic [PA_WIDTH -1 : 0]         mem_addr;
    logic                           mem_ack;

    logic                           mem_enable_response;
    logic [LINE_WIDTH -1 : 0]       mem_data;
    logic [ID_WIDTH -1 : 0]         mem_id_request;
    logic [ID_WIDTH -1 : 0]         mem_id_response;
    logic                           mem_in_use;

    ica #(
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

        .i_enable(enable),
        .i_va_addr(va_addr),
        .i_pa_addr(pa_addr),

        .o_stall(stall),
        .o_read_data(read_data),

        .o_mem_enable(mem_enable_request),
        .o_mem_addr(mem_addr),
        .o_mem_ack(mem_ack),

        .i_mem_enable(mem_enable_response),
        .i_mem_data(mem_data),
        .i_mem_id_request(mem_id_request),
        .i_mem_id_response(mem_id_response),
        .i_mem_in_use(mem_in_use)
    );

    always #5 clk = ~clk;

    task automatic printing();
        for (int i = 0; i < N_SECTORS; i++) begin
            for (int j = 0; j < N_LINES; j++) begin
                $display("| %h - %h | %b |", dut.tag[i][j], dut.memory[i][j], dut.valid_bit[i][j]);
            end
        end
        $display("_______________");
    endtask

    initial begin
        // $monitoroff;
        // rst = 1; #10; 
        // enable = 0; mem_enable_response = 1; mem_data = 16'hAABB; mem_id_response = 0; mem_id_request = 0; mem_in_use = 0; rst = 0; rnd = 0; #10;
        // $monitoron;
        // // test 0
        // enable = 1; va_addr = 8'h00; pa_addr = 8'h00; #20;
        // // printing();
        // // test 1
        // rnd = 1; va_addr = 8'h02; pa_addr = 8'h00; #20;
        // printing();

        // Common init
        rst = 1; enable = 0; rnd = 0;
        mem_enable_response = 0; mem_in_use = 0;
        mem_id_request = 2'b01;
        mem_id_response = 2'b01;
        mem_data = 16'hAABB;
        #20; rst = 0;

        // =============== TEST 1: Cold miss and fill ===============
        $display("\n[TEST 1] Cold miss + fill");
        va_addr = 8'h00; pa_addr = 8'h00;
        enable = 1;
        #10;  // Request sent (miss)

        // emulate memory response after 2 cycles
        #10; mem_enable_response = 1; #10; mem_enable_response = 0;
        #10;
        $display("After fill (expect one valid line)");
        printing();
        enable = 0;

        // =============== TEST 2: Cache hit ===============
        $display("\n[TEST 2] Cache hit");
        #10; enable = 1; va_addr = 8'h00; pa_addr = 8'h00;
        #10;
        $display("After hit (no new mem request expected)");
        printing();
        enable = 0;

        // =============== TEST 3: Conflict miss (same index, new tag) ===============
        $display("\n[TEST 3] Conflict miss / replacement");
        rnd = 1;  // choose different line
        va_addr = 8'h00; pa_addr = 8'h40;  // different tag but same index bits
        enable = 1;
        #10;
        mem_enable_response = 1; mem_data = 16'hCCDD; #10; mem_enable_response = 0;
        #10;
        $display("After conflict miss (replaced line)");
        printing();
        enable = 0;

        // =============== TEST 4: Different sector ===============
        $display("\n[TEST 4] Different sector access");
        rnd = 0;
        va_addr = 8'h20; pa_addr = 8'h20;  // different sector index bits
        enable = 1;
        #10;
        mem_enable_response = 1; mem_data = 16'hEEFF; #10; mem_enable_response = 0;
        #10;
        $display("After different sector fill");
        printing();
        enable = 0;

        #20;
        $display("\nSimulation done.\n");
        #1; $finish;
    end

    initial $monitor(
        "t:%2d | stall:%b | data:%h || m_enable:%b | m_addr:%h | m_ack:%b || state:%d | hit:%b |",
        $time, stall, read_data, mem_enable_response, mem_addr, mem_ack, dut.state, dut.hit
    );

endmodule