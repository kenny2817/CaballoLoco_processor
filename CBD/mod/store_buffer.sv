
module stb #(
    parameter VA_WIDTH,
    parameter N_LINES
) (
    input logic clk,
    input logic rst,

    input logic i_is_store,
    input logic i_was_load,
    input logic [VA_WIDTH -1 : 0] i_adress,
    input logic [VA_WIDTH -1 : 0] i_write_data,
    input logic i_was_hit_cache, // next step/cycle

    output logic o_valid_commit,
    output logic [VA_WIDTH -1 : 0] o_data_commit,
    output logic [VA_WIDTH -1 : 0] o_addr_commit,

    output logic o_hit,
    output logic o_exeption,
    output logic [VA_WIDTH -1 : 0] o_read_data
);
    localparam LINE_SELECT = $clog2(N_LINES);

    logic [VA_WIDTH -1 : 0]    address     [N_LINES];
    logic [VA_WIDTH -1 : 0]    data        [N_LINES];
    logic                      valid_bit   [N_LINES];
    
    logic [LINE_SELECT -1 : 0] oldest_line, newest_line, load_index;

    always_comb begin
        o_hit = 1'b0;
        load_index = '0; 
        
        for (int i = 0; i < N_LINES; i++) begin
            if (valid_bit[i] && (address[i] == i_adress)) begin
                o_hit = 1'b1;
                load_index = i;
            end
        end

        o_exeption = i_is_store && valid_bit[newest_line];
        o_read_data = data[load_index];

        o_valid_commit = valid_bit[oldest_line];
        o_data_commit = data[oldest_line];
        o_addr_commit = address[oldest_line];
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < N_LINES; i++) begin
                valid_bit[i] <= '0;
            end
            oldest_line <= '0;
            newest_line <= '0;
            load_index <= '0;
        end else begin
            if (i_was_hit_cache && valid_bit[oldest_line] && !i_was_load) begin // update if cache hit last cycle
                valid_bit[oldest_line] <= '0;
                oldest_line <= oldest_line + 1'b1;
            end
            if (i_is_store) begin // try to store in the buffer
                if (!valid_bit[newest_line]) begin
                    address[newest_line] <= i_adress;
                    data[newest_line] <= i_write_data;
                    valid_bit[newest_line] <= 1'b1;
                    newest_line <= newest_line + 1'b1;
                end
            end
        end
    end

endmodule

module stb_tb;
    
    parameter VA_WIDTH = 8;
    parameter N_LINES = 4;

    logic clk = 0, rst;
    logic i_is_store, i_was_load;
    logic [VA_WIDTH -1 : 0] i_adress, i_write_data;
    logic i_was_hit_cache;

    logic o_valid_commit;
    logic [VA_WIDTH -1 : 0] o_data_commit, o_addr_commit;
    logic o_hit, o_exeption;
    wire [VA_WIDTH -1 : 0] o_read_data;

    stb #(
        .VA_WIDTH(VA_WIDTH),
        .N_LINES(N_LINES)
    ) dut (
        .clk(clk),
        .rst(rst),

        .i_is_store(i_is_store),
        .i_was_load(i_was_load),
        .i_adress(i_adress),
        .i_write_data(i_write_data),
        .i_was_hit_cache(i_was_hit_cache),

        .o_valid_commit(o_valid_commit),
        .o_data_commit(o_data_commit),
        .o_addr_commit(o_addr_commit),

        .o_hit(o_hit),
        .o_exeption(o_exeption),
        .o_read_data(o_read_data)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("stb.vcd");
        $dumpvars(0, stb_tb);

        rst = 1; #10;
        rst = 0; #10;

        // Test 1: Store some data
        i_is_store = 1;
        i_was_load = 0;
        i_was_hit_cache = 0;

        i_adress = 8'h10; i_write_data = 8'hAA; #40;
        // too many writes
        i_adress = 8'h14; i_write_data = 8'hBB; #10;

        i_was_hit_cache = 1; i_was_load = 0; #10;
        i_was_hit_cache = 1; i_was_load = 1; #10;

        $finish();
    end;

    logic a;
    assign a = dut.valid_bit[dut.newest_line];
    initial $monitor(
        "t: %3t, Store %h at %h | excep: %b | data %h | data_inside: %h %h %h %h | store: %b | oldest: %h | newest: %h | valid: %b %b %b %b | ", 
        $time, i_write_data, i_adress, o_exeption, 
        o_read_data,
        dut.data[0], dut.data[1], dut.data[2], dut.data[3],
        dut.i_is_store, dut.oldest_line, dut.newest_line,
        dut.valid_bit[0], dut.valid_bit[1], dut.valid_bit[2], dut.valid_bit[3],
        a
    );

endmodule