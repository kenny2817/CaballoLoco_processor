import alu_pkg::*;

module alu #(
    parameter DATA_WIDTH
)
(
    input wire [DATA_WIDTH - 1 : 0] i_elemA,
    input wire [DATA_WIDTH - 1 : 0] i_elemB,
    input alu_op_e i_op,
    output logic [DATA_WIDTH - 1 : 0] o_output
);
always_comb begin
    case (i_op)
        ADD_OP: o_output = (i_elemA + i_elemB);
        SUB_OP: o_output = (i_elemA - i_elemB);
        AND_OP: o_output = (i_elemA & i_elemB);
        OR_OP: o_output = (i_elemA | i_elemB);
        default: o_output = 'x;
    endcase
end
endmodule