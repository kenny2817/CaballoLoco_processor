import alu_pkg::*;

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

    initial $monitor(
        "t=%3t | A= %h | B=%h | op=%b | out=%b |", 
        $time, elemA,, elemB, op, out
    );

endmodule