import alu_pkg::*;
import cmp_pkg::*;
import mdu_pkg::*;
import cache_pkg::*;
import cable_pkg::*;

package pipes_pkg;
    parameter int REG_WIDTH = 32;

    // DECODE STAGE
    typedef struct packed {
        logic [REG_WIDTH-1 : 0] instruction;
        logic [REG_WIDTH-1 : 0] pc;
    } cable_pipe_D_t;
    
    // EXECUTION STAGE
    typedef struct packed {
        logic                   jalr;
        logic                   use_flag;
        logic [REG_WIDTH-1 : 0] rs1;
        logic [REG_WIDTH-1 : 0] rs2;
        logic [REG_WIDTH-1 : 0] imm;
        logic [REG_WIDTH-1 : 0] pc;
        alu_control_t           alu_control;
        mdu_control_t           mdu_control;
        cmp_control_t           cmp_control;
        mem_control_t           mem_control;
        wb_control_t            wb_control;
    } cable_pipe_A_t;
    
    // MEMORY STAGE
    typedef struct packed {
        logic [REG_WIDTH-1 : 0] rs2;
        logic [REG_WIDTH-1 : 0] execution_result;
        mem_control_t           mem_control;
        wb_control_t            wb_control;
    } cable_pipe_M_t;
    
    // WRITE BACK STAGE
    typedef struct packed {
        logic [REG_WIDTH-1 : 0] execution_result;
        logic [REG_WIDTH-1 : 0] mem_data;
        logic                   is_load;
        wb_control_t            wb_control;
    } cable_pipe_W_t;

    // WRITE BACK COPIED STAGE
    typedef struct packed {
        logic [REG_WIDTH-1 : 0] mux_result;
        wb_control_t            wb_control;
    } cable_pipe_WC_t;
    
endpackage
