package cmp_pkg;
    localparam int CMP_OP_COUNT = 4;
    localparam int CMP_OP_WIDTH = $clog2(CMP_OP_COUNT);

    typedef enum logic [CMP_OP_WIDTH - 1 : 0] { 
        NOP,
        BEQ,
        BLT,
        BLE
    } cmp_op_e;
    
endpackage