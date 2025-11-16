package alu_pkg;

    typedef enum logic [2 : 0] {
        OP_ADD,
        OP_SUB,
        OP_AND,
        OP_OR,
        OP_XOR,
        OP_SLL,
        OP_SRL,
        OP_SRA
    } risk_alu_e;
    
    typedef enum logic [1:0] {
        OP_REG,    // Register value
        OP_IMM,    // Immediate value
        OP_PC,     // Program counter
        OP_ZERO    // Zero
    } risk_alu_operand_selector_e;
    
    typedef struct packed {
        risk_alu_e                  operation;
        risk_alu_operand_selector_e op1_sel;
        risk_alu_operand_selector_e op2_sel;
        logic                       use_unsigned;
    } alu_control_t;

endpackage