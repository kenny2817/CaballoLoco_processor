module cmp_tb;
    
    localparam DATA_WIDTH = 8;

    logic [DATA_WIDTH - 1 : 0] elemA;
    logic [DATA_WIDTH - 1 : 0] elemB;
    logic [1 : 0] op;
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
        op = 2'b00; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = 2'b01; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = 2'b10; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = 2'b11; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        elemB = 8'h07;
        op = 2'b01; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = 2'b10; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        op = 2'b11; #10;
        $display("A=%h, B=%h, Op=%b, Output=%b",elemA, elemB, op, out);
        $finish;
    end

endmodule