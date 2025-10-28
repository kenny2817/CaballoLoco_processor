
module dca #(
    parameter TLB_LINES, CACHE_LINES, STB_LINES, N_CACHE_SECTORS, LINE_WIDTH, REG_WIDTH, VA_WIDTH, PA_WIDTH
) (
    input logic clk,
    input logic rst,

    input logic i_is_load,
    input logic i_was_load,
    input logic i_is_store,
    input logic [VA_WIDTH -1 : 0] i_virtual_addr,
    input logic [REG_WIDTH -1 : 0] i_write_data,

    output logic o_data_loaded,
    output logic o_exeption
);
    
    logic hit_tlb;
    logic e_tlb;
    logic [REG_WIDTH -1 : 0] addr_tlb;
    logic valid_commit;
    logic [REG_WIDTH -1 : 0] data_commit;
    logic [REG_WIDTH -1 : 0] addr_commit;
    logic [REG_WIDTH -1 : 0] read_stb;
    logic hit_stb;
    logic e_stb;
    logic hit_cache;
    logic e_cache;
    logic [REG_WIDTH -1 : 0] read_cache;
    logic [REG_WIDTH -1 : 0] addr_cache;
    logic hit_W = '0;
    logic store_cache;


    always_comb begin
        addr_cache = i_is_load ? addr_tlb : addr_commit;
        store_cache = valid_commit & ~i_was_load;
        o_data_loaded = hit_stb ? read_stb : read_cache;
        o_exeption = e_tlb | e_stb | e_cache;
    end

    tlb #(
        .N_LINES(TLB_LINES),
        .VA_WIDTH(REG_WIDTH),
        .PA_WIDTH(REG_WIDTH)
    ) TLB (
        .clk(clk),
        .rst(rst),

        .i_virtual_addr(i_virtual_addr),

        .i_write_enable(NO),
        .i_write__virtual_ddr('x),
        .i_write_physical_addr('x),

        .o_hit(hit_tlb),
        .o_exeption(e_tlb),
        .o_physical_addr(addr_tlb)
    );

    cache #(
        .N_LINES(CACHE_LINES),
        .N_SECTORS(N_CACHE_SECTORS),
        .LINE_WIDTH(LINE_WIDTH),
        .REG_WIDTH(REG_WIDTH),
        .PA_WIDTH(REG_WIDTH),
        .TAG_WIDTH(REG_WIDTH - INDEX_WIDTH - OFFSET_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH)
    ) CACHE (
        .clk(clk),
        .rst(rst),

        .i_is_store(store_cache),
        .i_write_data(data_commit),
        .i_addr(addr_cache),

        .o_hit(hit_cache),
        .o_exeption(e_cache),
        .o_read_data(read_cache)
    );

    stb #(
        .VA_WIDTH(REG_WIDTH),
        .N_LINES(STB_LINES)
    ) STB (
        .clk(clk),
        .rst(rst),

        .i_adress(addr_tlb),
        .i_write_data(reg_b_M),
        .i_is_store(i_is_store),
        .i_was_load(i_was_load),
        .i_was_hit_cache(was_hit_cache),

        .o_hit(hit_stb),
        .o_exeption(e_stb),
        .o_read_data(read_stb),

        .o_valid_commit(valid_commit),
        .o_data_commit(data_commit),
        .o_addr_commit(addr_commit)
    );

endmodule

module dca_tb;

    localparam REG_WIDTH = 32;
    localparam VA_WIDTH = 32;
    localparam PA_WIDTH = 32;
    localparam TLB_LINES = 4;
    localparam CACHE_LINES = 2;
    localparam STB_LINES = 4;
    localparam N_CACHE_SECTORS = CACHE_LINES;
    localparam LINE_WIDTH = 2;

    logic clk = 0;
    logic rst;
    logic is_load;
    logic was_load;
    logic is_store;
    logic [VA_WIDTH -1 : 0] virtual_addr;
    logic [REG_WIDTH -1 : 0] write_data;
    logic [REG_WIDTH -1 : 0] data_loaded;
    logic exeption;

    dca #(
        .REG_WIDTH(REG_WIDTH),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH),
        .TLB_LINES(TLB_LINES),
        .CACHE_LINES(CACHE_LINES),
        .STB_LINES(STB_LINES),
        .N_CACHE_SECTORS(N_CACHE_SECTORS),
        .LINE_WIDTH(LINE_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .i_is_load(is_load),
        .i_was_load(was_load),
        .i_is_store(is_store),
        .i_virtual_addr(virtual_addr),
        .i_write_data(write_data),

        .o_data_loaded(data_loaded),
        .o_exeption(exeption)
    );

    initial clk = ~clk;

    initial begin
        $monitoroff;
        rst = 1; #1; rst = 0; #1;
        dut.TLB.virtual_addrs[0] = 0; dut.TLB.physical_addrs[0] = 0; dut.TLB.valid_bit[0] = 1;
        dut.TLB.virtual_addrs[1] = 1; dut.TLB.physical_addrs[1] = 2; dut.TLB.valid_bit[1] = 1;
        dut.CACHE.cache_tags[0][0] = 0; dut.CACHE.cache_valid_bit[0][0] = 1; dut.CACHE.cache_mem[0][0][0] = 1; dut.CACHE.cache_mem[0][0][1] = 3;
        dut.CACHE.cache_tags[1][0] = 0; dut.CACHE.cache_valid_bit[1][0] = 1; dut.CACHE.cache_mem[1][0][0] = 2; dut.CACHE.cache_mem[1][0][1] = 4;

        for (int i = 0; i < TLB_LINES; i++) begin
            $display("TLB Line %0d: V:%0h P:%0h Vb:%b", i, dut.TLB.virtual_addrs[i], dut.TLB.physical_addrs[i], dut.TLB.valid_bit[i]);
        end
        for (int i = 0; i < N_CACHE_SECTORS; i++) begin
            for (int j = 0; j < CACHE_LINES / N_CACHE_SECTORS; j++) begin
                $display(
                    "CACHE Sector %0d Line %0d: Tag:%0h Vb:%b Data[0]:%0h [1]:%0h", 
                    i, j, dut.CACHE.cache_tags[i][j], dut.CACHE.cache_valid_bit[i][j], 
                    dut.CACHE.cache_mem[i][j][0], dut.CACHE.cache_mem[i][j][1]
                );
            end
        end

        is_load = 1;
        was_load = 0;
        is_store = 0;
        virtual_addr = 0;
        write_data = 1;
        @(posedge clk);

        is_load = 0;
        was_load = 1;
        is_store = 0;
        virtual_addr = 1;
        write_data = 2;
        @(posedge clk);

        is_load = 1;
        was_load = 0;
        is_store = 0;
        virtual_addr = 0;
        write_data = 3;
        @(posedge clk);

        $finish

    end

    initial $monitor(
        "t:%3t | l:%b w %b | s:%b | v:%h | w:%h | d:%h | e:%b |",
        $time, is_load, was_load, is_store, virtual_addr, write_data, data_loaded, exeption
    );

endmodule