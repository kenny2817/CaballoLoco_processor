import opcodes_pkg::*;
import cmp_pkg::*;
import alu_pkg::*;

module opd_32 #(
    parameter NUM_REG
) (
    input logic [REG_WIDTH -1 : 0] i_instruction,
    input logic i_nop,

    output logic [REG_SELECT -1 : 0] o_select_a,
    output logic [REG_SELECT -1 : 0] o_select_b,
    output logic [REG_SELECT -1 : 0] o_select_c,
    output logic o_is_write,
    output logic o_is_load,
    output logic o_is_store,
    output logic o_is_cmp,
    output cmp_op_e o_cmp_op,
    output alu_op_e o_alu_op,
    output logic [REG_WIDTH -1 : 0] o_offset

);
    localparam REG_WIDTH = 32;
    localparam REG_SELECT = $clog2(NUM_REG);
    localparam IMMEDIATE_WIDTH = REG_WIDTH - OPCODES_WIDTH - 2 * REG_SELECT;

    opcodes_e opcode;
    assign opcode = opcodes_e'((i_nop) ? NOP_OP : i_instruction[REG_WIDTH -1 -: OPCODES_WIDTH]);


    logic [REG_WIDTH -1 : 0] offset_lw, offset_st, offset_br, offset_jp;
    assign offset_lw = {
        {(OPCODES_WIDTH + 2 * REG_SELECT){i_instruction[REG_WIDTH - OPCODES_WIDTH - REG_SELECT -1]}}, 
        i_instruction[REG_WIDTH - OPCODES_WIDTH - REG_SELECT -1 -: REG_SELECT],
        i_instruction[IMMEDIATE_WIDTH - REG_SELECT -1 : 0]
    };
    assign offset_st = {
        {(OPCODES_WIDTH + 2 * REG_SELECT){i_instruction[IMMEDIATE_WIDTH -1]}},
        i_instruction[IMMEDIATE_WIDTH -1 : 0]
    };
    assign offset_br = {
        {(OPCODES_WIDTH + 2 * REG_SELECT -2){i_instruction[IMMEDIATE_WIDTH -1]}},
        i_instruction[IMMEDIATE_WIDTH -1 : 0], 
        2'b00 //no need to adress byte of an instruction, do we?
    }; 
    assign offset_jp = {
        {(OPCODES_WIDTH - 2){i_instruction[REG_WIDTH - OPCODES_WIDTH -1]}},
        i_instruction[REG_WIDTH - OPCODES_WIDTH -1 : 0], 
        2'b00
    };

    assign o_select_a = i_instruction[REG_WIDTH - OPCODES_WIDTH -1 -: REG_SELECT];
    assign o_select_b = i_instruction[REG_WIDTH - OPCODES_WIDTH - REG_SELECT -1 -: REG_SELECT];
    assign o_select_c = i_instruction[IMMEDIATE_WIDTH -1 -: REG_SELECT];

    always_comb begin
        case (opcode)
            ADD_OP: begin
                o_is_write = '1;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = ADD;
                o_offset = 'x;
            end
            SUB_OP: begin
                o_is_write = '1;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = SUB;
                o_offset = 'x;
            end
            AND_OP: begin
                o_is_write = '1;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = AND;
                o_offset = 'x;
            end
            OR_OP: begin
                o_is_write = '1;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = OR;
                o_offset = 'x;
            end
            MUL_OP: begin
                o_is_write = '1;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = MUL;
                o_offset = 'x;
            end
            DIV_OP: begin
                o_is_write = '1;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = DIV;
                o_offset = 'x;
            end
            XOR_OP: begin
                o_is_write = '1;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = XOR;
                o_offset = 'x;
            end
            LW_OP: begin
                o_is_write = '1;
                o_is_load = '1;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = ADD;
                o_offset = offset_lw;
            end
            SW_OP: begin
                o_is_write = '0;
                o_is_load = '0;
                o_is_store = '1;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = ADD;
                o_offset = offset_st;
            end
            BEQ_OP: begin
                o_is_write = '0;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '1;
                o_cmp_op = BEQ;
                o_alu_op = ADD;
                o_offset = offset_br;
            end
            BLT_OP: begin
                o_is_write = '0;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '1;
                o_cmp_op = BLT;
                o_alu_op = ADD;
                o_offset = offset_br;
            end
            BLE_OP: begin
                o_is_write = '0;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '1;
                o_cmp_op = BLE;
                o_alu_op = ADD;
                o_offset = offset_br;
            end
            JMP_OP: begin
                o_is_write = '0;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '1;
                o_cmp_op = BLE;
                o_alu_op = ADD;
                o_offset = offset_jp;
            end
            NOP_OP: begin
                o_is_write = '0;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = 'x;
                o_cmp_op = NOP;
                o_alu_op = OR;
                o_offset = 'x;
            end
            default: begin
                // not recognized -> do nothing
                o_is_write = '0;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = 'x;
                o_cmp_op = NOP;
                o_alu_op = OR;
                o_offset = 'x;
            end
        endcase 
    end
endmodule
