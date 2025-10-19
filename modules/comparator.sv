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


module cmp_tb;
    
    localparam DATA_WIDTH = 8;

    logic [DATA_WIDTH - 1 : 0] elemA;
    logic [DATA_WIDTH - 1 : 0] elemB;
    cmp_op_e op;
    logic out;

    cmp #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .i_elemA(elemA),
        .i_elemB(elemB),
        .i_op(op),
        .o_output(out)
    );

    initial begin
        op = NOP; elemA = 8'h05; elemB = 8'h05; #10;
        op = BEQ; #10;
        op = BLT; #10;
        op = BLE; #10;
        op = BEQ; elemB = 8'h07; #10;
        op = BLT; #10;
        op = BLE; #10;
        $finish;
    end

    initial $monitor("t=%3t | A= %h | B=%h | op=%b | out=%b |", $time, elemA,, elemB, op, out);

endmodule