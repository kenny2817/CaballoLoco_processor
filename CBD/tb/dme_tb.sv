
import cache_pkg::*;

module dme_tb;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam TLB_LINES      = 4;
    localparam CACHE_SECTORS  = 4;
    localparam CACHE_LINES    = 4;
    localparam CACHE_BYTES    = 16;
    localparam STB_LINES      = 4;
    localparam REG_WIDTH      = 32;
    localparam VA_WIDTH       = 32;
    localparam PA_WIDTH       = 32;
    localparam INDEX_WIDTH    = $clog2(CACHE_LINES);
    
    // Missing params in DUT declaration, inferred for TB
    localparam LINE_WIDTH     = 128; 
    localparam ID_WIDTH       = 4;

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    logic                         clk;
    logic                         rst;
    logic [INDEX_WIDTH -1 : 0]    rnd;

    // CPU Interface
    mem_control_t                 i_control;
    logic [VA_WIDTH -1 : 0]       i_virtual_addr;
    logic [REG_WIDTH -1 : 0]      i_write_data;

    logic                         o_data_loaded; // Note: DUT output width mismatch? Logic is 1 bit, data is REG_WIDTH. 
                                                 // Assuming o_data_loaded is actually [REG_WIDTH-1:0] in implementation 
                                                 // based on "assign o_data_loaded = ... data"
    logic [REG_WIDTH -1 : 0]      o_data_read_bus; // Using bus for observation if o_data_loaded is actually vector
    logic                         o_exeption;
    logic                         o_stall;

    // TLB Write Interface
    logic                         i_write_enable;
    logic [PA_WIDTH -1 : 0]       i_physical_addr;

    // Memory Interface
    logic                         o_mem_enable;
    logic [PA_WIDTH -1 : 0]       o_mem_addr;
    logic [REG_WIDTH -1 : 0]      o_mem_data;
    logic                         o_mem_write;
    logic                         o_mem_ack;

    logic                         i_mem_enable;
    logic [LINE_WIDTH -1 : 0]     i_mem_data;
    logic [ID_WIDTH -1 : 0]       i_mem_id_request;
    logic [ID_WIDTH -1 : 0]       i_mem_id_response;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    dme #(
        .TLB_LINES(TLB_LINES),
        .CACHE_SECTORS(CACHE_SECTORS),
        .CACHE_LINES(CACHE_LINES),
        .CACHE_BYTES(CACHE_BYTES),
        .STB_LINES(STB_LINES),
        .REG_WIDTH(REG_WIDTH),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),
        .i_control(i_control),
        .i_virtual_addr(i_virtual_addr),
        .i_write_data(i_write_data),
        .o_data_loaded(o_data_loaded), // Wired to 1-bit wire, check DUT definition if this should be bus
        .o_exeption(o_exeption),
        .o_stall(o_stall),
        .i_write_enable(i_write_enable), // TLB write
        .i_physical_addr(i_physical_addr),
        .o_mem_enable(o_mem_enable),
        .o_mem_addr(o_mem_addr),
        .o_mem_data(o_mem_data),
        .o_mem_write(o_mem_write),
        .o_mem_ack(o_mem_ack),
        .i_mem_enable(i_mem_enable),
        .i_mem_data(i_mem_data),
        .i_mem_id_request(i_mem_id_request),
        .i_mem_id_response(i_mem_id_response)
    );

    // -------------------------------------------------------------------------
    // Clock & Random Gen
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    always_ff @(posedge clk) begin
        rnd <= rnd + 1; // Simple pseudo-random for replacement policy
    end

    // -------------------------------------------------------------------------
    // Tasks
    // -------------------------------------------------------------------------
    task tlb_write(input logic [VA_WIDTH-1:0] vaddr, input logic [PA_WIDTH-1:0] paddr);
        begin
            @(posedge clk);
            i_write_enable = 1;
            i_virtual_addr = vaddr;   // TLB uses the shared virtual addr port
            i_physical_addr = paddr;
            @(posedge clk);
            i_write_enable = 0;
            i_virtual_addr = 0;
            i_physical_addr = 0;
            $display("[TB] TLB Map: VA 0x%h -> PA 0x%h", vaddr, paddr);
        end
    endtask

    task cpu_store(input logic [VA_WIDTH-1:0] addr, input logic [REG_WIDTH-1:0] data);
        begin
            @(posedge clk);
            while(o_stall) @(posedge clk); // Wait for stall
            i_control.is_store = 1;
            i_control.is_load = 0;
            i_control.size = SIZE_WORD;
            i_virtual_addr = addr;
            i_write_data = data;
            @(posedge clk);
            i_control.is_store = 0;
            i_write_data = 0;
            i_virtual_addr = 0;
            $display("[TB] CPU Store: VA 0x%h Data 0x%h", addr, data);
        end
    endtask

    task cpu_load(input logic [VA_WIDTH-1:0] addr);
        begin
            @(posedge clk);
            while(o_stall) @(posedge clk);
            i_control.is_store = 0;
            i_control.is_load = 1;
            i_control.size = SIZE_WORD;
            i_virtual_addr = addr;
            @(posedge clk);
            i_control.is_load = 0;
            i_virtual_addr = 0;
            $display("[TB] CPU Load Request: VA 0x%h", addr);
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Stimulus
    // -------------------------------------------------------------------------
    initial begin
        // Initialize inputs
        rst = 1;
        i_control = '0;
        i_virtual_addr = 0;
        i_write_data = 0;
        i_write_enable = 0; // TLB
        i_physical_addr = 0;
        
        // Memory inputs (from RAM)
        i_mem_enable = 0;
        i_mem_data = 0;
        i_mem_id_request = 0;
        i_mem_id_response = 0;

        // Reset sequence
        repeat(10) @(posedge clk);
        rst = 0;
        $display("[TB] Reset released");

        // 1. Configure TLB (Map VA 0x1000 to PA 0x8000)
        tlb_write(32'h00001000, 32'h00008000);
        repeat(2) @(posedge clk);

        // 2. Store Data to 0x1000
        cpu_store(32'h00001000, 32'hDEADBEEF);
        repeat(2) @(posedge clk);

        // 3. Load Data from 0x1000 (Should hit STB or Cache)
        cpu_load(32'h00001000);
        
        // Wait a bit to see result
        repeat(10) @(posedge clk);

        $finish;
    end

    // -------------------------------------------------------------------------
    // Simple Memory Responder (Mock RAM)
    // -------------------------------------------------------------------------
    // If the cache misses and asks for memory, we just say "Okay here is 0"
    // to prevent the logic from stalling forever.
    always_ff @(posedge clk) begin
        i_mem_enable <= 0;
        if (o_mem_enable) begin
            $display("[TB] MEM REQ: Addr 0x%h (Write: %b)", o_mem_addr, o_mem_write);
            if (!o_mem_write) begin
                // Read request, send data back next cycle
                i_mem_enable <= 1;
                i_mem_data <= 128'hAABBCCDDEEFF00112233445566778899; // Garbage line data
            end
        end
    end

endmodule
