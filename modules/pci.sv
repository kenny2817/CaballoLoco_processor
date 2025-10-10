module pci #(
    parameter REG_WIDTH
) (
    input logic i_select,
    input logic [REG_WIDTH -1 : 0] i_pc,
    input logic [REG_WIDTH-1 : 0] i_offset,
    output logic [REG_WIDTH -1 : 0] o_pc
);

    localparam PC_INCREMENT = $clog2(REG_WIDTH);

    assign o_pc = i_select ? (i_pc + i_offset) : (i_pc + 1);

endmodule