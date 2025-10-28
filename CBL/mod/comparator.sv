import cmp_pkg::*;

module cmp #(
    parameter DATA_WIDTH
) (
    input logic [DATA_WIDTH - 1 : 0] i_elemA,
    input logic [DATA_WIDTH - 1 : 0] i_elemB,
    input cmp_op_e i_op,
    output logic o_output
);
    always_comb begin
        case (i_op)
            NOP: o_output = '0;
            BEQ: o_output = (i_elemA == i_elemB);
            BLT: o_output = (i_elemA < i_elemB);
            BLE: o_output = (i_elemA <= i_elemB);
            default: o_output = 'x;
        endcase
    end
endmodule
