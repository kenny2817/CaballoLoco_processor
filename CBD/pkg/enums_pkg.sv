package enums

    typedef enum logic [1 : 0] {
        SIZE_BYTE,
        SIZE_HALF,
        SIZE_WORD
    } risk_mem_e;

    typedef enum logic [2 : 0] { 
        OP_BEQ,
        OP_BNE,
        OP_BLT,
        OP_BGE
    } risk_cmp_e;

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


    typedef enum logic [6:0] {
        // === Base Integer (I) ===
        // ALU R-type
        INSTR_ADD,
        INSTR_SUB,
        INSTR_XOR,
        INSTR_OR,
        INSTR_AND,
        INSTR_SLL,
        INSTR_SRL,
        INSTR_SRA,
        INSTR_SLT,
        INSTR_SLTU,
        
        // ALU I-type (immediate)
        INSTR_ADDI,
        INSTR_XORI,
        INSTR_ORI,
        INSTR_ANDI,
        INSTR_SLLI,
        INSTR_SRLI,
        INSTR_SRAI,
        INSTR_SLTI,
        INSTR_SLTIU,
        
        // Branch
        INSTR_BEQ,
        INSTR_BNE,
        INSTR_BLT,
        INSTR_BGE,
        INSTR_BLTU,
        INSTR_BGEU,
        
        // Load
        INSTR_LB,
        INSTR_LH,
        INSTR_LW,
        INSTR_LBU,
        INSTR_LHU,
        
        // Store
        INSTR_SB,
        INSTR_SH,
        INSTR_SW,
        
        // Jump
        INSTR_JAL,
        INSTR_JALR,
        
        // Upper immediate
        INSTR_LUI,
        INSTR_AUIPC,
        
        // System
        INSTR_ECALL,
        INSTR_EBREAK,
        
        // === M Extension (Multiply/Divide) ===
        INSTR_MUL,
        INSTR_MULH,
        INSTR_MULHSU,
        INSTR_MULHU,
        INSTR_DIV,
        INSTR_DIVU,
        INSTR_REM,
        INSTR_REMU,
        
        // Invalid/Unknown
        INSTR_INVALID
    } riscv_instr_e;
    
    // Instruction format types
    typedef enum logic [2:0] {
        FMT_R,      // Register-register
        FMT_I,      // Immediate
        FMT_S,      // Store
        FMT_B,      // Branch
        FMT_U,      // Upper immediate
        FMT_J,      // Jump
        FMT_UNKNOWN
    } instr_format_e;
    
endpackage