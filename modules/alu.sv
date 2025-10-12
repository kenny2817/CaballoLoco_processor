import alu_pkg::*;

module alu #(
    parameter DATA_WIDTH
) (
    input logic [DATA_WIDTH - 1 : 0] i_elemA,
    input logic [DATA_WIDTH - 1 : 0] i_elemB,
    input alu_op_e i_op,
    output logic [DATA_WIDTH - 1 : 0] o_output
);
    always_comb begin
        case (i_op)
            ADD: o_output = (i_elemA + i_elemB);
            SUB: o_output = (i_elemA - i_elemB);
            AND: o_output = (i_elemA & i_elemB);
            OR: o_output = (i_elemA | i_elemB);
            XOR: o_output = (i_elemA ^ i_elemB);
            MUL: o_output = (i_elemA * i_elemB);
            DIV: o_output = (i_elemA / i_elemB);
            default: o_output = 'x;
        endcase
    end
endmodule

module alu_tb;
    
    localparam DATA_WIDTH = 8;

    logic [DATA_WIDTH - 1 : 0] elemA;
    logic [DATA_WIDTH - 1 : 0] elemB;
    alu_op_e op;
    logic [DATA_WIDTH - 1 : 0] out;

    alu #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .i_elemA(elemA),
        .i_elemB(elemB),
        .i_op(op),
        .o_output(out)
    );

    initial begin
        op = ADD; elemA = 8'h05; elemB = 8'h05; #10;
        op = SUB; #10;
        op = AND; #10;
        op = OR; #10;
        op = ADD; elemB = 8'h07; #10;
        op = SUB; #10;
        op = AND; #10;
        op = OR; #10;
        $finish;
    end

    initial $monitor("t=%3t | A= %h | B=%h | op=%b | out=%b |", $time, elemA,, elemB, op, out);

endmodule