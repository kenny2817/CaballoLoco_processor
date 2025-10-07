import cmp_pkg::*;

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
        elemA = 8'h05;
        elemB = 8'h05;
        op = NOP; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = BEQ; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = BLT; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = BLE; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        elemB = 8'h07;
        op = BEQ; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = BLT; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = BLE; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        $finish;
    end

endmodule