package opcodes_pkg;

    localparam NUM_OPCODES = 12;
    localparam OPCODES_WIDTH = $clog2(NUM_OPCODES);

    typedef enum logic [OPCODES_WIDTH - 1 : 0] {
        OR_OP,  // op + ra + rb + rc
        ADD_OP, // op + ra + rb + rc 
        SUB_OP, // op + ra + rb + rc
        AND_OP, // op + ra + rb + rc
        MUL_OP, // op + ra + rb + rc
        DIV_OP, // op + ra + rb + rc
        XOR_OP, // op + ra + rb + rc
        LW_OP,  // op + ra + offset + rc + offset
        SW_OP,  // op + ra + rb + offset
        BEQ_OP, // op + ra + rb + offset
        BLT_OP, // op + ra + rb + offset
        BLE_OP, // op + ra + rb + offset
        JMP_OP, // op + offset
        NOP_OP  // no operation
    } opcodes_e;
    
endpackage