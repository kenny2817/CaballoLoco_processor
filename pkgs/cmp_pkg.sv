package cmp_pkg;
    localparam CMP_OP_COUNT = 4;
    localparam CMP_OP_WIDTH = $clog2(CMP_OP_COUNT);

    typedef enum logic [CMP_OP_WIDTH - 1 : 0] { 
        NOP,
        BEQ,
        BLT,
        BLE
        // DONT_CARE = {CMP_OP_WIDTH{1'bx}} // if there are more options
    } cmp_op_e;
    
endpackage