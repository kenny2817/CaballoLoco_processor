package const_pkg;

    localparam int REG_NUM = 32;
    localparam int REG_ADDR = $clog2(REG_NUM);
    localparam int REG_WIDTH = 32;
    localparam int VA_WIDTH = 32;
    localparam int PA_WIDTH = 32;
    localparam int ID_WIDTH = 4;
    localparam int CACHE_BYTES = 16;
    localparam int LINE_WIDTH = CACHE_BYTES * 8;

    localparam int ITLB_LINES = 4;
    localparam int ICACHE_SECTORS = 4;
    localparam int ICACHE_LINES = 2;
    localparam int IINDEX_WIDTH   = (ICACHE_LINES > 1) ? $clog2(ICACHE_LINES) : 1,

    localparam int DTLB_LINES = 2;
    localparam int DCACHE_SECTORS = 4;
    localparam int DCACHE_LINES = 1;
    localparam int DSTB_LINES = 4;
    localparam int DINDEX_WIDTH   = (DCACHE_LINES > 1) ? $clog2(DCACHE_LINES) : 1,
    
    localparam int MEM_STAGES = 5;
    localparam int MDU_STAGES = 5;


    // register width
// number of sectors
// number of lines per sector
// number of bytes per element
// virtual address width
// physical address width (this should be already the tag!)
// memory id width
endpackage