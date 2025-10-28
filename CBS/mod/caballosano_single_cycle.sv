
import cmp_pkg::*;
import alu_pkg::*;
import opcodes_pkg::*;

module cbs #(
    parameter NUM_REG,
    parameter REG_WIDTH,
    parameter NUM_INSTR,
    parameter NUM_MEM
) (
    input logic clk,
    input logic rst
);
    localparam REG_SELECT = $clog2(NUM_REG);
    localparam INSTR_SELECT = $clog2(NUM_INSTR);
    localparam MEM_SELECT = $clog2(NUM_MEM);

    logic [INSTR_SELECT -1 : 0] pc, new_pc;
    logic [REG_WIDTH -1 : 0] instruction, alu_data, new_reg, mem_data, reg_a, reg_b, a, b, offset;
    logic [REG_SELECT -1 : 0] reg_a_select, reg_b_select, reg_c_select;
    wire [REG_WIDTH -1 : 0] regs [NUM_REG];
    logic is_write, is_load, is_store, is_cmp, cmp_data;
    alu_op_e alu_op;
    cmp_op_e cmp_op;

    // PROGRAM COUNTER
    reg_mono #(
        .DATA_WIDTH(INSTR_SELECT)
    ) PC (
        .clk(clk),
        .rst(rst),
        .i_write_enable(1'b1),
        .i_write_data(new_pc),
        .o_read_data(pc)
    );

    // PROGRAM COUNTER INCREMENTER
    assign new_pc = cmp_data ? (pc + alu_data[INSTR_SELECT -1 : 0]) : (pc +1);

    // INSTRUCTIONS
    reg_bank_mono #( 
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_INSTR)
    ) INSTRUCTIONS (
        .clk(clk),
        .rst(rst),

        .i_write_enable(1'b0),
        .i_select(pc),
        .i_write_data('x),
        
        .o_read_data(instruction)
    );

    // OPCODE DECODER
    opd_32 #(
        .NUM_REG(NUM_REG)
    ) OPD_32 (
        .i_instruction(instruction),  
        .i_nop(1'b0),

        .o_select_a(reg_a_select),
        .o_select_b(reg_b_select),
        .o_select_c(reg_c_select),
        .o_is_write(is_write),
        .o_is_load(is_load),
        .o_is_store(is_store),
        .o_is_cmp(is_cmp),
        .o_cmp_op(cmp_op),
        .o_alu_op(alu_op),
        .o_offset(offset)
    );

    // REGISTERS
    reg_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_REG)
    ) REGISTERS (
        .clk(clk),
        .rst(rst),

        .i_write_enable(is_write),
        .i_write_select(reg_c_select),
        .i_write_data(new_reg),
        
        .o_read_data(regs)
    );

    // REGISTER A
    assign reg_a = regs[reg_a_select];

    assign a = (is_cmp) ? {{(REG_WIDTH - INSTR_SELECT){1'b0}}, pc} : reg_a;

    // REGISTER B
    assign reg_b = regs[reg_b_select];

    assign b = (is_store | is_load | is_cmp) ? offset : reg_b;

    // ALU
    alu #(
        .DATA_WIDTH(REG_WIDTH)
    ) ALU (
        .i_elemA(a),
        .i_elemB(b),

        .i_op(alu_op),
        .o_output(alu_data)
    );

    // MEMORY
    reg_bank_mono #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_MEM)
    ) MEM (
        .clk(clk),
        .rst(rst),
        .i_write_enable(is_store),
        .i_select(alu_data[MEM_SELECT -1 : 0]),
        .i_write_data(reg_b),

        .o_read_data(mem_data)
    );    

    // MUX {ALU MEM}
    assign new_reg = is_load ? mem_data : alu_data;

    // CMP
    cmp #(
        .DATA_WIDTH(REG_WIDTH)
    ) CMP (
        .i_elemA(reg_a),
        .i_elemB(reg_b),
        
        .i_op(cmp_op),
        .o_output(cmp_data)
    );

endmodule
