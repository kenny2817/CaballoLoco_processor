import opcodes_pkg::*;
import cmp_pkg::*;
import alu_pkg::*;

module opd_32 #(
    parameter NUM_REG
) (
    input logic [REG_WIDTH -1 : 0]      i_instruction,
    input logic                         i_nop,

    output logic [REG_SELECT -1 : 0]    o_select_a,
    output logic [REG_SELECT -1 : 0]    o_select_b,
    output logic [REG_SELECT -1 : 0]    o_select_c,
    output logic                        o_is_write,
    output logic                        o_is_load,
    output logic                        o_is_store,
    output logic                        o_is_cmp,
    output cmp_op_e                     o_cmp_op,
    output alu_op_e                     o_alu_op,
    output logic [REG_WIDTH -1 : 0]     o_offset

);
    localparam REG_WIDTH        = 32;
    localparam REG_SELECT       = $clog2(NUM_REG);
    localparam IMMEDIATE_WIDTH  = REG_WIDTH - OPCODES_WIDTH - 2 * REG_SELECT;

    opcodes_e                           opcode;
    assign opcode = opcodes_e'((i_nop) ? NOP_OP : i_instruction[REG_WIDTH -1 -: OPCODES_WIDTH]);
    // offsets
        logic [REG_WIDTH -1 : 0]            offset_lw;
        logic [REG_WIDTH -1 : 0]            offset_st;
        logic [REG_WIDTH -1 : 0]            offset_br;
        logic [REG_WIDTH -1 : 0]            offset_jp;


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

    task automatic set_signals(
        input logic is_write,
        input logic is_load,
        input logic is_store,
        input logic is_cmp,
        input logic [CMP_OP_WIDTH-1:0] cmp_op,
        input logic [ALU_OP_WIDTH-1:0] alu_op,
        input logic [OFFSET_WIDTH-1:0] offset
    );
        o_is_write = is_write;
        o_is_load  = is_load;
        o_is_store = is_store;
        o_is_cmp   = is_cmp;
        o_cmp_op   = cmp_op;
        o_alu_op   = alu_op;
        o_offset   = offset;
    endtask


    always_comb begin
        if (i_nop) begin
            set_signals('0, '0, '0, '0, NOP, NOP, 'x');
        end else begin
            case (opcode)
                ADD_OP:     set_signals('1, '0, '0, '0, NOP, ADD, 'x);
                SUB_OP:     set_signals('1, '0, '0, '0, NOP, SUB, 'x);
                AND_OP:     set_signals('1, '0, '0, '0, NOP, AND, 'x);
                OR_OP:      set_signals('1, '0, '0, '0, NOP,  OR, 'x);
                MUL_OP:     set_signals('1, '0, '0, '0, NOP, MUL, 'x);
                DIV_OP:     set_signals('1, '0, '0, '0, NOP, DIV, 'x);
                XOR_OP:     set_signals('1, '0, '0, '0, NOP, XOR, 'x);
                LW_OP:      set_signals('1, '1, '0, '0, NOP, ADD, offset_lw);
                SW_OP:      set_signals('0, '0, '1, '0, NOP, ADD, offset_st);
                BEQ_OP:     set_signals('0, '0, '0, '1, BEQ, ADD, offset_br);
                BLT_OP:     set_signals('0, '0, '0, '1, BLT, ADD, offset_br);
                BLE_OP:     set_signals('0, '0, '0, '1, BLE, ADD, offset_br);
                JMP_OP:     set_signals('0, '0, '0, '1, JMP, ADD, offset_jp);
                default:    set_signals('0, '0, '0, '0, NOP,  OR, 'x);
            endcase
        end
    end
endmodule
