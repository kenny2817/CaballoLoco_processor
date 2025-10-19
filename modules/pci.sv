module pci #(
    parameter REG_WIDTH
) (
    input logic i_select,
    input logic [REG_WIDTH -1 : 0] i_pc,
    input logic [REG_WIDTH-1 : 0] i_offset,
    output logic [REG_WIDTH -1 : 0] o_pc
);
    assign o_pc = i_select ? (i_pc + i_offset) : (i_pc +1);
endmodule


module pci_tb;

    localparam REG_WIDTH = 32;

    logic clk = 0, select;
    logic [REG_WIDTH -1 : 0] offset = '0, pc = '0, new_pc;

    pci #(
        .REG_WIDTH(REG_WIDTH)
    ) dut (
        .i_select(select),
        .i_offset(offset),
        .i_pc(pc),
        .o_pc(new_pc)
    );

    always #10 pc = new_pc;

    initial begin
        select = 0; offset = 8'd42; #10;
        select = 1; #10;
        select = 0; #100;
        $finish;
    end

    initial $monitor("t=%4t | sel= %b | off=%4d | pc=%4d |", $time, select, offset, new_pc);

endmodule