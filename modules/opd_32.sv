import opcodes_pkg::*;
import cmp_pkg::*;
import alu_pkg::*;

module opd_32 #(
    parameter NUM_REG
) (
    input logic [REG_WIDTH -1 : 0] i_instruction,
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
    assign opcode = opcodes_e'(i_instruction[REG_WIDTH -1 -: OPCODES_WIDTH]);
    
    logic [IMMEDIATE_WIDTH -1 : 0] immediate;
    assign immediate = i_instruction[IMMEDIATE_WIDTH -1 : 0];

    logic [IMMEDIATE_WIDTH -1 : 0] offset_lw, offset_st, offset_br;
    assign offset_lw = {{(REG_WIDTH - IMMEDIATE_WIDTH){immediate[IMMEDIATE_WIDTH -1]}}, i_instruction[IMMEDIATE_WIDTH -1 -: REG_SELECT], immediate[IMMEDIATE_WIDTH - REG_SELECT -1 : 0]};
    assign offset_st = {{(REG_WIDTH - IMMEDIATE_WIDTH){immediate[IMMEDIATE_WIDTH -1]}}, immediate};
    assign offset_br = {{(REG_WIDTH - IMMEDIATE_WIDTH -2){immediate[IMMEDIATE_WIDTH -1]}}, immediate, 2'b00}; //no need to adress byte of an instruction, do we?

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
            default: begin
                // not recognized -> do nothing
                o_is_write = '0;
                o_is_load = '0;
                o_is_store = '0;
                o_is_cmp = '0;
                o_cmp_op = NOP;
                o_alu_op = OR;
                o_offset = 'x;
            end
        endcase 
    end
endmodule


module opd_32_tb;

    localparam NUM_REG = 32;
    localparam REG_WIDTH = 32;
    localparam REG_SELECT = $clog2(NUM_REG);

    logic [REG_WIDTH -1 : 0] instruction, offset;
    logic [REG_SELECT -1 : 0] select_a, select_b, select_c;
    logic is_write, is_load, is_store, is_cmp;
    cmp_op_e cmp_op;
    alu_op_e alu_op;
    
    opd_32 #(
        .NUM_REG(NUM_REG)
    ) dut (
        .i_instruction(instruction),   
        .o_select_a(select_a),
        .o_select_b(select_b),
        .o_select_c(select_c),
        .o_is_write(is_write),
        .o_is_load(is_load),
        .o_is_store(is_store),
        .o_is_cmp(is_cmp),
        .o_cmp_op(cmp_op),
        .o_alu_op(alu_op),
        .o_offset(offset)   
    );

    initial begin
        #10;
        instruction = {ADD_OP, 5'd5, 5'd5, 5'd2, {(REG_WIDTH - OPCODES_WIDTH - REG_SELECT * 3){1'b0}}}; #10;
        instruction = {SUB_OP, 5'd6, 5'd5, 5'd3, {(REG_WIDTH - OPCODES_WIDTH - REG_SELECT * 3){1'b0}}}; #10;
        $finish;
    end

    initial $monitor("t=%3t | instr=%b | sel_a=%d | sel_b=%d | sel_c=%d | iw=%b | il=%b | is=%b | icmp=%b | cmp_op=%b | alu_op=%b | off=%d | op=%d", 
        $time, instruction, select_a, select_b, select_c, is_write, is_load, is_store, is_cmp, cmp_op, alu_op, offset, dut.opcode);

endmodule
