`timescale 1ns/1ps
import cache_pkg::*;

module dca_tb;

    // ------------------------------------------------------------
    // Parameters (adapt them to match your design)
    // ------------------------------------------------------------
    localparam REG_WIDTH   = 32;
    localparam N_SECTORS   = 2;
    localparam N_LINES     = 4;
    localparam N_ELEMENTS  = 4;
    localparam N_BYTES     = 4;
    localparam VA_WIDTH    = 32;
    localparam PA_WIDTH    = 32;
    localparam ID_WIDTH    = 4;

    localparam ELEMENT_WIDTH = N_BYTES * 8;
    localparam LINE_WIDTH    = N_ELEMENTS * ELEMENT_WIDTH;

    // ------------------------------------------------------------
    // DUT signals
    // ------------------------------------------------------------
    logic clk = 0;
    logic rst = 1;

    logic [$clog2(N_LINES)-1:0] rnd;

    mem_data_t i_load, i_store;
    logic      i_hit;
    logic [PA_WIDTH-1:0] i_pa;

    logic o_hit, o_stall;
    logic [ELEMENT_WIDTH-1:0] o_read_data;

    logic o_mem_enable;
    logic [PA_WIDTH-1:0] o_mem_addr;
    logic [LINE_WIDTH-1:0] o_mem_data;
    logic o_mem_type;
    logic o_mem_ack;

    logic i_mem_enable;
    logic [LINE_WIDTH-1:0] i_mem_data;
    logic [ID_WIDTH-1:0] i_mem_id_request;
    logic [ID_WIDTH-1:0] i_mem_id_response;

    // Memory response modeling
    int mem_latency = 5;
    int mem_countdown = 0;

    // ------------------------------------------------------------
    // Instantiate the DUT
    // ------------------------------------------------------------
    dca #(
        .REG_WIDTH(REG_WIDTH),
        .N_SECTORS(N_SECTORS),
        .N_LINES(N_LINES),
        .N_BYTES(N_BYTES),
        .PA_WIDTH(PA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .rnd(rnd),

        .i_hit(i_hit),
        .i_load(i_load),
        .i_store(i_store),
        .i_pa(i_pa),

        .o_hit(o_hit),
        .o_miss(o_stall),
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

    // ------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------
    always #5 clk <= ~clk;

    // ------------------------------------------------------------
    // Simple memory model
    // Returns a full cache line after some cycles
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (o_mem_enable && !o_mem_type) begin
            // load request
            $display("[%0t] MEM READ REQ addr=%h id=%0d",
                $time, o_mem_addr, i_mem_id_request);
            mem_countdown <= mem_latency;
            i_mem_id_response <= i_mem_id_request;
        end

        if (mem_countdown > 0) begin
            mem_countdown <= mem_countdown - 1;

            if (mem_countdown == 1) begin
                // send memory line
                i_mem_enable <= 1;
                i_mem_data <= {LINE_WIDTH{1'b0}} | 32'hDEADBEEF; 
                $display("[%0t] MEM RESP id=%0d data=DEADBEEF...", 
                    $time, i_mem_id_response);
            end else begin
                i_mem_enable <= 0;
            end
        end else begin
            i_mem_enable <= 0;
        end
    end

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------
    initial begin
        // Init
        i_load = '0;
        i_store = '0;
        i_hit = 0;
        i_pa = 0;
        i_mem_id_request = 1;
        rnd = 0;

        // Apply reset
        repeat (5) @(posedge clk);
        rst = 0;

        $display("=== TEST BEGIN ===");

        // --------------------------------------------------------
        // LOAD MISS → memory fetch → LOAD HIT
        // --------------------------------------------------------

        i_load.enable = 1;
        i_load.address = 32'h0000_0000;
        i_load.size = SIZE_WORD;
        rnd = 0;
        i_pa = 32'h0000_0000;

        $display("[%0t] LOAD MISS request", $time);

        // Wait until stall clears and hit occurs
        wait(o_hit == 1);
        @(posedge clk);

        $display("[%0t] LOAD HIT read_data=%h", $time, o_read_data);

        // --------------------------------------------------------
        // STORE HIT
        // --------------------------------------------------------

        i_load.enable  = 0;
        i_store.enable = 1;
        i_store.address = 32'h0000_0000;
        i_store.data = 32'hAABBCCDD;

        $display("[%0t] STORE HIT attempt", $time);

        repeat (3) @(posedge clk);

        // --------------------------------------------------------
        // END
        // --------------------------------------------------------

        $display("=== TEST DONE ===");
        #20 $finish;
    end

endmodule
