
module cache #(
    parameter N_LINES,
    parameter N_SECTORS,
    parameter LINE_WIDTH,
    parameter REG_WIDTH,
    parameter PA_WIDTH,
    parameter TAG_WIDTH,
    parameter INDEX_WIDTH,
    parameter OFFSET_WIDTH
) (
    input logic clk,
    input logic rst,

    input logic i_is_store,
    input logic [PA_WIDTH -1 : 0] i_addr,
    input logic [REG_WIDTH -1 : 0] i_write_data, 

    output logic o_hit,
    output logic o_exeption,
    output logic [REG_WIDTH -1 : 0] o_read_data
);
    localparam N_L_SECTOR = N_LINES /N_SECTORS;
    localparam LINE_SELECT_WIDTH = $clog2(N_L_SECTOR);

    logic [REG_WIDTH -1 : 0] cache_mem [N_SECTORS][N_L_SECTOR][LINE_WIDTH];
    logic [TAG_WIDTH -1 : 0] cache_tags [N_SECTORS][N_L_SECTOR];
    logic cache_valid_bit [N_SECTORS][N_L_SECTOR];

    logic [TAG_WIDTH -1 : 0] addr_tag;
    logic [INDEX_WIDTH -1 : 0] addr_idx;
    logic [OFFSET_WIDTH -1 : 0] addr_off;

    logic [LINE_SELECT_WIDTH -1 : 0] hit_index;

    assign addr_tag = i_addr[PA_WIDTH -1 : OFFSET_WIDTH + INDEX_WIDTH];
    assign addr_idx = i_addr[OFFSET_WIDTH + INDEX_WIDTH -1 : OFFSET_WIDTH];
    assign addr_off = i_addr[OFFSET_WIDTH -1 : 0];

    always_comb begin
        o_hit = 1'b0;
        o_exeption = 1'b1;
        o_read_data = 'x;
        hit_index = 'x;

        for (int i = 0; i < N_L_SECTOR; i++) begin
            if (cache_valid_bit[addr_idx][i] && (cache_tags[addr_idx][i] == addr_tag)) begin
                o_hit = 1'b1;
                o_exeption = 1'b0;
                o_read_data = cache_mem[addr_idx][i][addr_off];
                hit_index = i;
            end
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < N_SECTORS; i++) begin
                for (int j = 0; j < N_L_SECTOR; j++) begin
                    cache_valid_bit[i][j] <= 1'b0;
                end
            end
        end else begin
            if (i_is_store && o_hit) begin
                cache_mem[addr_idx][hit_index][addr_off] <= i_write_data;
            end
        end
    end

endmodule


module cache_tb;

    // Parameters
    localparam REG_WIDTH = 32;
    localparam PA_WIDTH = 8;
    localparam N_LINES = 16;
    localparam N_SECTORS = 4;
    localparam LINE_WIDTH = 4; // Bytes per line
    localparam OFFSET_WIDTH = $clog2(LINE_WIDTH);
    localparam INDEX_WIDTH = $clog2(N_SECTORS);
    localparam TAG_WIDTH = PA_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;

    // Testbench signals
    logic clk = 0;
    logic rst;
    logic i_is_store;
    logic [PA_WIDTH-1:0] i_addr;
    logic [REG_WIDTH-1:0] i_write_data;
    logic o_hit;
    logic o_exeption;
    logic [REG_WIDTH-1:0] o_read_data;

    // Instantiate the cache module
    cache # (
        .N_LINES(N_LINES),
        .N_SECTORS(N_SECTORS),
        .LINE_WIDTH(LINE_WIDTH),
        .REG_WIDTH(REG_WIDTH),
        .PA_WIDTH(PA_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .i_is_store(i_is_store),
        .i_addr(i_addr),
        .i_write_data(i_write_data),
        .o_hit(o_hit),
        .o_exeption(o_exeption),
        .o_read_data(o_read_data)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        rst = 1; i_is_store = 0; i_addr = 0; i_write_data = 0; #10;
        rst = 0; #10;
        dut.cache_tags[0][0] = 4'hA; dut.cache_valid_bit[0][0] = 1'b1; dut.cache_mem[0][0][0] = 8'hFF;
        i_is_store = 1; i_addr = 8'h00; i_write_data = 32'hDEADBEEF; #10;
        i_is_store = 0; i_addr = 8'ha0; #10;
        i_is_store = 0; i_addr = 8'h10; #10;
        i_is_store = 1; i_addr = 8'h04; i_write_data = 32'hCAFEBABE;#10;
        i_is_store = 0; i_addr = 8'h04; #10;
        $finish;
    end

    initial $monitor(
        "t: %3t | is_store: %b | addr: %h | write_data: %h | hit: %b | excep: %b | read_data: %h | %h |",
        $time, i_is_store, i_addr, i_write_data, o_hit, o_exeption, o_read_data, dut.cache_tags[0][0], dut.cache_mem[0][0][0]
    );


endmodule
