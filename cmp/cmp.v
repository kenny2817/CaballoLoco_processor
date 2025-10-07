module cmp #(
    parameter DATA_WIDTH,
    localparam OP_WIDTH = 2
)
(
    input wire [DATA_WIDTH - 1 : 0] i_elemA,
    input wire [DATA_WIDTH - 1 : 0] i_elemB,
    input wire [OP_WIDTH - 1 : 0] i_op,
    output logic o_output
);
always_comb begin
    unique case (i_op)
        2'b00: o_output = '0;                   // NOP
        2'b01: o_output = (i_elemA == i_elemB); // BEQ
        2'b10: o_output = (i_elemA < i_elemB);  // BLT
        2'b11: o_output = (i_elemA <= i_elemB); // BLE
    endcase
end
endmodule