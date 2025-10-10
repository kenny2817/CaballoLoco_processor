`timescale 1ns/100ps

import opcodes_pkg::*;
import cmp_pkg::*;
import alu_pkg::*;

module opd_32_tb;

    localparam NUM_REG = 32;
    localparam REG_WIDTH = 32;
    localparam REG_SELECT = $clog2(NUM_REG);

    logic [REG_WIDTH -1 : 0] instruction;
    logic [REG_SELECT -1 : 0] select_a;
    logic [REG_SELECT -1 : 0] select_b;
    logic [REG_SELECT -1 : 0] select_c;
    logic is_write;
    logic is_load;
    logic is_store;
    logic is_cmp;
    cmp_op_e cmp_op;
    alu_op_e alu_op;
    logic [REG_WIDTH -1 : 0] offset;
    
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
        instruction = {ADD_OP, 5'd5, 5'd5, 5'd2, {(REG_WIDTH - OPCODES_WIDTH - REG_SELECT * 3){1'b0}}};
        #10;
        instruction = {SUB_OP, 5'd6, 5'd5, 5'd3, {(REG_WIDTH - OPCODES_WIDTH - REG_SELECT * 3){1'b0}}};
        #10;
        
        $finish;
    end

    initial begin
        $monitor("t=%3t | instr=%b | sel_a=%d | sel_b=%d | sel_c=%d | iw=%b | il=%b | is=%b | icmp=%b | cmp_op=%b | alu_op=%b | off=%d | op=%d", 
                  $time, instruction, select_a, select_b, select_c, is_write, is_load, is_store, is_cmp, cmp_op, alu_op, offset, dut.opcode);
    end

endmodule
