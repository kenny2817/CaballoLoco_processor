
package mdu_pkg;

    typedef enum logic [2 : 0] {
        OP_MUL,    // (S) x (S) Low Word
        OP_MULH,   // (S) x (S) High Word
        OP_MULHSU, // (S) x (U) High Word
        OP_MULHU,  // (U) x (U) High Word
        OP_DIV,
        OP_DIVU,
        OP_REM,
        OP_REMU
    } risk_mdu_e;

    typedef struct packed {
        logic                       enable;
        risk_mdu_e                  operation;
    } mdu_control_t;

endpackage