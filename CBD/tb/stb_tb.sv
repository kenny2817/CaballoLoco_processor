module stb_tb;
    
    parameter VA_WIDTH = 8;
    parameter N_LINES = 4;

    logic clk = 0, rst;
    logic is_store, load_cache;
    logic [VA_WIDTH -1 : 0] adress, write_data;
    logic hit_cache;
    logic stall;

    logic valid_commit;
    logic [VA_WIDTH -1 : 0] data_commit, addr_commit;
    logic hit, exeption;
    wire [VA_WIDTH -1 : 0] read_data;

    stb #(
        .VA_WIDTH(VA_WIDTH),
        .N_LINES(N_LINES)
    ) dut (
        .clk(clk),
        .rst(rst),

        .i_is_store(is_store),
        .i_adress(adress),
        .i_write_data(write_data),

        .i_load_cache(load_cache),
        .i_hit_cache(hit_cache),

        .o_stall(stall),

        .o_valid_commit(valid_commit),
        .o_data_commit(data_commit),
        .o_addr_commit(addr_commit),

        .o_hit(hit),
        .o_read_data(read_data)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("stb.vcd");
        $dumpvars(0, stb_tb);

        rst = 1; #10;
        rst = 0; #10;

        // Test 1: Store some data
        is_store = 1;
        load_cache = 0;
        hit_cache = 0;

        adress = 8'h10; write_data = 8'hAA; #40;
        // too many writes
        adress = 8'h14; write_data = 8'hBB; #10;

        hit_cache = 1; load_cache = 0; #10;
        hit_cache = 1; load_cache = 1; #10;

        $finish();
    end;

    initial $monitor(
        "t: %3t, Store %h at %h | excep: %b | data %h | data_inside: %h %h %h %h | store: %b | oldest: %h | newest: %h | valid: %b %b %b %b | stall:%b |", 
        $time, write_data, adress, exeption, 
        read_data,
        dut.data[0], dut.data[1], dut.data[2], dut.data[3],
        is_store, dut.oldest_line, dut.newest_line,
        dut.valid_bit[0], dut.valid_bit[1], dut.valid_bit[2], dut.valid_bit[3],
        stall
    );

endmodule