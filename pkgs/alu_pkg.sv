package alu_pkg;
    localparam int ALU_OP_COUNT = 4;
    localparam int ALU_OP_WIDTH = $clog2(ALU_OP_COUNT);

    typedef enum logic [ALU_OP_WIDTH - 1 : 0] {
        ADD_OP,
        SUB_OP,
        AND_OP,
        OR_OP
    } alu_op_e;

endpackage