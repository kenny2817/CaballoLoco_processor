package cmp_pkg;

    typedef enum logic [2 : 0] { 
        OP_BEQ,
        OP_BNE,
        OP_BLT,
        OP_BGE
    } risk_cmp_e;

    typedef struct packed {
        logic       enable;
        risk_cmp_e  operation;
    } cmp_control_t;
    
endpackage