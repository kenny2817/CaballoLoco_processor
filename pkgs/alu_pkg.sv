package alu_pkg;
    localparam ALU_OP_COUNT = 7;
    localparam ALU_OP_WIDTH = $clog2(ALU_OP_COUNT);

    typedef enum logic [ALU_OP_WIDTH - 1 : 0] {
        ADD,
        SUB,
        AND,
        OR,
        MUL,
        DIV,
        XOR
    } alu_op_e;

endpackage