
package cable_pkg;
    import const_pkg::*;
    import enums_pkg::*;
    
// Decoded instruction structure
    typedef struct packed {
        riscv_instr_e               instr_type;
        instr_format_e              format;
        logic [REG_ADDR  -1 : 0]    rs1;
        logic [REG_ADDR  -1 : 0]    rs2;
        logic [REG_ADDR  -1 : 0]    rd;
        logic [REG_WIDTH -1 : 0]    imm;
        logic                       valid;
    } decoded_instr_t;

// write back control signal
    typedef struct packed {
        logic                       is_write_back;
        logic [REG_ADDR  -1 : 0]    rd;
    } wb_control_t;

// data cache

    // memory control signal
    typedef struct packed {
        logic                       is_load;
        logic                       is_store;
        risk_mem_e                  size;
        logic                       use_unsigned;
    } mem_control_t;

    // memory data signal
    typedef struct packed {
        logic                       enable;
        risk_mem_e                  size;
        logic [REG_WIDTH -1 : 0]    address;
        logic [REG_WIDTH -1 : 0]    data;
        logic                       use_unsigned;
    } mem_data_t;

// pipes

    // DECODE STAGE
    typedef struct packed {
        logic [REG_WIDTH -1 : 0]    instruction;
        logic [REG_WIDTH -1 : 0]    pc;
    } cable_pipe_D_t;
    
    // EXECUTION STAGE
    typedef struct packed {
        logic                       jalr;
        logic                       use_flag;
        logic [REG_ADDR  -1 : 0]    select_rs1;
        logic [REG_ADDR  -1 : 0]    select_rs2;
        logic [REG_WIDTH -1 : 0]    rs1;
        logic [REG_WIDTH -1 : 0]    rs2;
        logic [REG_WIDTH -1 : 0]    imm;
        logic [REG_WIDTH -1 : 0]    pc;
        alu_control_t               alu_control;
        mdu_control_t               mdu_control;
        cmp_control_t               cmp_control;
        mem_control_t               mem_control;
        wb_control_t                wb_control;
    } cable_pipe_A_t;
    
    // MEMORY STAGE
    typedef struct packed {
        logic [REG_WIDTH -1 : 0]    rs2;
        logic [REG_WIDTH -1 : 0]    execution_result;
        mem_control_t               mem_control;
        wb_control_t                wb_control;
    } cable_pipe_M_t;
    
    // WRITE BACK STAGE
    typedef struct packed {
        logic [REG_WIDTH -1 : 0]    execution_result;
        logic [REG_WIDTH -1 : 0]    mem_data;
        logic                       is_load;
        wb_control_t                wb_control;
    } cable_pipe_W_t;

    // WRITE BACK COPIED STAGE
    typedef struct packed {
        logic [REG_WIDTH -1 : 0]    mux_result;
        wb_control_t                wb_control;
    } cable_pipe_WC_t;

// execution signals

    // mdu control signal
    typedef struct packed {
        logic                       enable;
        risk_mdu_e                  operation;
    } mdu_control_t;

    // alu control signal
    typedef struct packed {
        risk_alu_e                  operation;
        risk_alu_operand_selector_e op1_sel;
        risk_alu_operand_selector_e op2_sel;
        logic                       use_unsigned;
    } alu_control_t;

    // cmp control signal
    typedef struct packed {
        logic                       enable;
        risk_cmp_e                  operation;
    } cmp_control_t;

endpackage
