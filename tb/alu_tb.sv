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
        elemA = 8'h05;
        elemB = 8'h05;
        op = ADD; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = SUB; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = AND; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = OR; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        elemB = 8'h07;
        op = ADD; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = SUB; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = AND; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = OR; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        $finish;
    end

endmodule