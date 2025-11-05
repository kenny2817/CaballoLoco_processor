module tlb_tb;

    localparam N_LINES = 4;
    localparam VA_WIDTH = 8;
    localparam PA_WIDTH = 8;

    logic clk = 0, rst;
    logic write_enable;
    logic [VA_WIDTH -1 : 0] write_virtual_addr;
    logic [PA_WIDTH -1 : 0] write_physical_addr;
    logic [VA_WIDTH -1 : 0] read_virtual_addr;
    logic [PA_WIDTH -1 : 0] read_physical_addr;
    logic exeption;

    tlb #(
        .N_LINES(N_LINES),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .i_write_enable(write_enable),
        .i_write_virtual_addr(write_virtual_addr),
        .i_write_physical_addr(write_physical_addr),

        .i_virtual_addr(read_virtual_addr),

        .o_physical_addr(read_physical_addr),
        .o_exeption(exeption)
    ); 

    always #5 clk = ~clk;

    initial begin   
        $monitoroff;
        rst = 1; #10; 
        rst = 0; #10;

        write_enable = 1;
        write_virtual_addr = 1; write_physical_addr = 2; #10;
        write_virtual_addr = 2; write_physical_addr = 3; #10;
        write_virtual_addr = 3; write_physical_addr = 4; #10;
        write_virtual_addr = 4; write_physical_addr = 5; #10;
        write_virtual_addr = 5; write_physical_addr = 6; #10;
        write_enable = 0; #10;
        $monitoron;
        
        read_virtual_addr = 1; #10;
        read_virtual_addr = 2; #10;
        read_virtual_addr = 3; #10;
        read_virtual_addr = 4; #10;
        read_virtual_addr = 5; #10;

        $finish();
    end

    initial $monitor(
        "t: %3d | v: %h | p: %h | e: %b || oldest: %d",
        $time, read_virtual_addr, read_physical_addr, exeption, dut.oldest_line
    );  

endmodule