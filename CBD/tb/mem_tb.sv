module mem_tb;
    localparam PA_WIDTH      = 8;
    localparam LINE_WIDTH    = 32;
    localparam ID_WIDTH      = 4;
    localparam STAGES        = 5;

    localparam logic [PA_WIDTH-1:0] MAX_ADDR = (1<<PA_WIDTH) - 1;

    // -------------------
    // Testbench Signals
    // -------------------

    // Module Inputs
    logic                         clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // we consider 10 time unit period
    end

    logic                         rst;
    logic                         i_mem_enable;
    logic                         i_mem_write;
    logic [PA_WIDTH   -1 : 0]     i_mem_addr;
    logic [LINE_WIDTH -1 : 0]     i_mem_data;
    logic [ID_WIDTH   -1 : 0]     i_mem_id;

    // Module Outputs
    logic                        o_mem_enable;
    logic [LINE_WIDTH    -1 : 0] o_mem_data;
    logic [ID_WIDTH      -1 : 0] o_mem_id_response;

    integer errors = 0;
    integer tests = 0;

    logic [LINE_WIDTH-1:0] rd_data;
    logic [ID_WIDTH-1:0] rd_id;
    
    // Device Under Test instance (dut)

    memory #(
        .PA_WIDTH(PA_WIDTH), 
        .LINE_WIDTH(LINE_WIDTH), 
        .ID_WIDTH(ID_WIDTH), 
        .STAGES(STAGES)
    ) dut (
        .clk(clk),
        .rst(rst),
        .i_mem_enable(i_mem_enable),
        .i_mem_write(i_mem_write),
        .i_mem_addr(i_mem_addr),
        .i_mem_data(i_mem_data),
        .i_mem_id(i_mem_id),
        .o_mem_enable(o_mem_enable),
        .o_mem_data(o_mem_data),
        .o_mem_id_response(o_mem_id_response)
    );

    // -------------------
    // Helper tasks
    // -------------------

    // 1-cycle request
    task automatic drive_req(
                            input string desc,
                            input logic write, // automatic task so that each call has its own allocated local variables on the stack
                            input logic [PA_WIDTH-1:0] addr,
                            input logic [LINE_WIDTH-1:0] data,
                            input logic [ID_WIDTH-1:0] id);
    begin
        $display("\n%s", desc);
        i_mem_write  = write;
        i_mem_addr   = addr;
        i_mem_data   = data;
        i_mem_id     = id;
        i_mem_enable = 1'b1;
        @(posedge clk); // sync task to next clock edge (single cycle pulse)
        // deassert inputs next cycle (single-cycle valid pulse)
        i_mem_enable = 1'b0;
        // keep other signals stable for one cycle to avoid x propagation
        i_mem_write  = 1'b0;
        i_mem_addr   = '0;
        i_mem_data   = '0;
        i_mem_id     = '0;
    end
    endtask

    // Wait for next response and return values
    task automatic wait_and_check_response(output logic [LINE_WIDTH-1:0] r_data,
                                           output logic [ID_WIDTH-1:0] r_id,
                                           input int timeout_cycles = STAGES*2); //arbitrary value, could also be STAGES+10 or *10 
    int cnt;
    begin
        cnt = 0;
        // to avoid unwanted X values 
        r_data = '0;
        r_id = '0;
        // wait for o_mem_enable pulse
        while (!o_mem_enable && cnt < timeout_cycles) begin
            @(posedge clk);
            cnt++;
        end
        if (!o_mem_enable) begin
            $display("ERROR: timeout waiting for response");
            errors++;
        end else begin
            r_data = o_mem_data;
            r_id   = o_mem_id_response;
            // consume the response cycle
            @(posedge clk);
        end
    end
    endtask

    // convenience assert
    task automatic check_equal(input string testname,
                               input logic [LINE_WIDTH-1:0] got_data,
                               input logic [LINE_WIDTH-1:0] exp_data,
                               input logic [ID_WIDTH-1:0] got_id,
                               input logic [ID_WIDTH-1:0] exp_id);
    begin
        tests++;
        if (got_data !== exp_data || got_id !== exp_id) begin
            $display("FAIL %s: got data=0x%08h id=%0d expected data=0x%08h id=%0d",
                     testname, got_data, got_id, exp_data, exp_id);
            errors++;
        end else begin
            $display("PASS %s", testname);
        end
    end
    endtask

    // -------------------
    // Testcases
    // -------------------

    initial begin
        // init
        rst = 1;
        i_mem_enable = 0;
        i_mem_write  = 0;
        i_mem_addr   = '0;
        i_mem_data   = '0;
        i_mem_id     = '0;
        repeat (4) @(posedge clk);
        rst = 0;
        @(posedge clk); //we wait for 5 stages

        // ---------------------------------------------
        // Test 0: reset check
        // ---------------------------------------------

        $display("\n=== Reset behaviour test ===");
        if (o_mem_enable !== 1'b0 || o_mem_data !== '0 || o_mem_id_response !== '0) begin
            $display("FAIL reset: outputs not zero (o_mem_enable=%0b o_mem_data=0x%0h o_mem_id=%0d)",
                     o_mem_enable, o_mem_data, o_mem_id_response);
            errors++;
        end else $display("PASS reset outputs zero");


        // ---------------------------------------------
        // Test 1: simple write -> expect echo at response
        // ---------------------------------------------

        drive_req("=== Test1: simple write echo ===", 1, 8'h05, 32'hDEADBEEF, 4'd1);
        // wait for response (write echo)
        wait_and_check_response(rd_data, rd_id);
        check_equal("write_echo", rd_data, 32'hDEADBEEF, rd_id, 4'd1);

        // ---------------------------------------------
        // Test 2: write then immediate read (forwarding)
        // ---------------------------------------------

        // cycle N: write A=0x10 value V1 id=2
        drive_req("=== Test2: write then immediate read (forwarding) ===\nCycle N", 1, 8'h10, 32'hAAAAAAAA, 4'd2);
        // cycle N+1: issue read to same addr id=3
        drive_req("Cycle N+1", 0, 8'h10, '0, 4'd3);
        // collect first response (should be for first request, write-echo)
        wait_and_check_response(rd_data, rd_id);
        check_equal("write_echo_2", rd_data, 32'hAAAAAAAA, rd_id, 4'd2);
        // collect second response (read) -> expected forwarded value AAAAAAAAA
        wait_and_check_response(rd_data, rd_id);
        check_equal("read_forwarded", rd_data, 32'hAAAAAAAA, rd_id, 4'd3);

        // ---------------------------------------------
        // Test 3: overwrite and later read (value persisted)
        // ---------------------------------------------

        drive_req("=== Test3: overwrite then read ===\n Write V1", 1, 8'h20, 32'h11111111, 4'd4); // write V1
        drive_req("Write V2", 1, 8'h20, 32'h22222222, 4'd5); // write V2 (immediately following)
        // consume two responses
        wait_and_check_response(rd_data, rd_id); check_equal("write1_echo", rd_data, 32'h11111111, rd_id, 4'd4);
        wait_and_check_response(rd_data, rd_id); check_equal("write2_echo", rd_data, 32'h22222222, rd_id, 4'd5);
        // now read later (will get V2)
        drive_req("Read V2", 0, 8'h20, '0, 4'd6);
        wait_and_check_response(rd_data, rd_id);
        check_equal("read_after_overwrite", rd_data, 32'h22222222, rd_id, 4'd6);

        // ---------------------------------------------
        // Test 4: multiple different addresses and ordering
        // ---------------------------------------------

        drive_req("=== Test4: multiple in-flight ordering ===", 1, 8'h30, 32'hAAAA0001, 4'd7);
        drive_req("", 0, 8'h31, '0, 4'd8);
        drive_req("", 1, 8'h32, 32'hBBBB0002, 4'd9);
        // Expect three responses in order
        wait_and_check_response(rd_data, rd_id); check_equal("resp7", rd_data, 32'hAAAA0001, rd_id, 4'd7);
        wait_and_check_response(rd_data, rd_id); check_equal("resp8", rd_data, 32'h00000000 /*unknown?*/, rd_id, 4'd8);
            // Note: if reading uninitialized address, value depends on memory init; avoid relying on zero.
            // Prefer writing then reading same address.
        wait_and_check_response(rd_data, rd_id); check_equal("resp9", rd_data, 32'hBBBB0002, rd_id, 4'd9);

        // ---------------------------------------------
        // Test 5: write and read tp address 0
        // ---------------------------------------------

        // write to addr 0
        drive_req("=== Edge addresses test ===\nwrite addr 0", 1, 0, 32'hCAFEBABE, 4'd10);
        wait_and_check_response(rd_data, rd_id);
        check_equal("edge_write_addr0", rd_data, 32'hCAFEBABE, rd_id, 4'd10);
        // read addr 0
        drive_req("read addr 0", 0, 0, '0, 4'd11);
        wait_and_check_response(rd_data, rd_id);
        check_equal("edge_read_addr0", rd_data, 32'hCAFEBABE, rd_id, 4'd11);

        // ---------------------------------------------
        // Test 6: write to MAX_ADDR
        // ---------------------------------------------

        drive_req("write max addr", 1, MAX_ADDR, 32'h12345678, 4'd12);
        wait_and_check_response(rd_data, rd_id);
        check_equal("edge_write_max", rd_data, 32'h12345678, rd_id, 4'd12);
        // read max addr
        drive_req("read max addr", 0, MAX_ADDR, '0, 4'd13);
        wait_and_check_response(rd_data, rd_id);
        check_equal("edge_read_max", rd_data, 32'h12345678, rd_id, 4'd13);

        // ---------------------------------------------
        // Test 7: issue 3 requests and verify ids preserved
        // ---------------------------------------------

        drive_req("=== Multi-ID ordering test ===\nid 6 write", 1, 8'h40, 32'h0A0A0A0A, 4'd6);
        drive_req("id 7 read",  0, 8'h41, '0, 4'd7);
        drive_req("id 8 write", 1, 8'h42, 32'h0B0B0B0B, 4'd8);
        wait_and_check_response(rd_data, rd_id); check_equal("multi_id_6", rd_data, 32'h0A0A0A0A, rd_id, 4'd6);
        wait_and_check_response(rd_data, rd_id); check_equal("multi_id_7", rd_data, 32'h00000000 /*unspecified unless written*/, rd_id, 4'd7);
        wait_and_check_response(rd_data, rd_id); check_equal("multi_id_8", rd_data, 32'h0B0B0B0B, rd_id, 4'd8);

        // ---------------------------------------------
        // Test 8: ensure responses don't contain X/Z
        // ---------------------------------------------

        // simple write/read to produce a response in rd_data/rd_id
        drive_req("=== X/Z presence check ===\nxz check write", 1, 8'h50, 32'hDEADCAFE, 4'd14);
        wait_and_check_response(rd_data, rd_id);
        if ((^rd_data) === 1'bx || (^rd_id) === 1'bx) begin
            $display("FAIL X/Z detected in response (data=%0h id=%0d)", rd_data, rd_id);
            errors++;
        end else $display("PASS no X/Z in response");

        // Summary

        $display("\n=== TEST SUMMARY ===");
        if (errors == 0) $display("ALL TESTS PASSED (%0d tests)", tests);
        else $display("FAILED: %0d errors out of %0d tests", errors, tests);
        $finish;
    end

endmodule
