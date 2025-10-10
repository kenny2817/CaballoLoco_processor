
import cmp_pkg::*;
import alu_pkg::*;

module cbs #(
    parameter NUM_REG,
    parameter REG_WIDTH,
    parameter NUM_INSTR,
    parameter NUM_MEM
) (
    input logic clk,
    input logic rst,
    input logic [NUM_INSTR * REG_WIDTH -1 : 0] i_instructions,
    input logic [NUM_MEM * REG_WIDTH -1 : 0] i_mem,
    output logic o_mem_store_enable,
    output logic [MEM_SELECT -1 : 0] o_mem_store_select,
    output logic [REG_WIDTH -1 : 0] o_mem_store_word
);
    localparam REG_SELECT = $clog2(NUM_REG);
    localparam INSTR_SELECT = $clog2(NUM_INSTR);
    localparam MEM_SELECT = $clog2(NUM_MEM);

    logic [INSTR_SELECT -1 : 0] pc, new_pc;
    logic [REG_WIDTH -1 : 0] instruction, alu_data, new_reg, mem_data, reg_a, reg_b, a, b, offset;
    logic [REG_SELECT -1 : 0] reg_a_select, reg_b_select, reg_c_select;
    logic [NUM_REG * REG_WIDTH -1 : 0] regs;
    // logic [NUM_MEM * REG_WIDTH -1 : 0] mems;
    logic is_write, is_load, is_store, is_cmp, cmp_data;
    alu_op_e alu_op;
    cmp_op_e cmp_op;

    assign o_mem_store_enable = is_store;
    assign o_mem_store_select = alu_data;
    assign o_mem_store_word = reg_b;
// PROGRAM COUNTER
    register #(
        .DATA_WIDTH(INSTR_SELECT),
        .NUM_REG(1)
    ) PC (
        .clk(clk),
        .rst(rst),
        .i_write_enable(1'b1),
        .i_write_data(new_pc),
        .o_read_data(pc)
    );

// PROGRAM COUNTER INCREMENTER
    pci #(
        .REG_WIDTH(INSTR_SELECT)
    ) PCI (
        .i_select(cmp_data),
        .i_offset(offset[INSTR_SELECT -1 : 0]),
        .i_pc(pc),
        .o_pc(new_pc)
    );

// INSTRUCTION
    mux #(
        .NUM_INPUTS(NUM_INSTR),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_INSTRUCTION (
        .i_data_bus(i_instructions),
        .i_select(pc),
        .o_output(instruction)
    );

// OPCODE DECODER
    opd_32 #(
        .NUM_REG(NUM_REG)
    ) OPD_32 (
        .i_instruction(instruction),   
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
    register_bank #(
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
    mux #(
        .NUM_INPUTS(NUM_REG),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_A_0 (
        .i_data_bus(regs),
        .i_select(reg_a_select),
        .o_output(reg_a)
    );

    mux #(
        .NUM_INPUTS(2),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_A_1 (
        .i_data_bus({{(REG_WIDTH - INSTR_SELECT){1'b0}}, pc, reg_a}),
        .i_select(is_cmp),
        .o_output(a)
    );

// REGISTER B
    mux #(
        .NUM_INPUTS(NUM_REG),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_B_0 (
        .i_data_bus(regs),
        .i_select(reg_b_select),
        .o_output(reg_b)
    );

    mux #(
        .NUM_INPUTS(2),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_B_1 (
        .i_data_bus({offset, reg_b}),
        .i_select(is_store || is_load || is_cmp),
        .o_output(b)
    );

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
    mux #(
        .NUM_INPUTS(NUM_MEM),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_MEM (
        .i_data_bus(i_mem),
        .i_select(alu_data[MEM_SELECT -1 : 0]),
        .o_output(mem_data)
    );

// MUX {ALU MEM}
    mux #(
        .NUM_INPUTS(2),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_ALU_MEM (
        .i_data_bus({mem_data, alu_data}),
        .i_select(is_load),
        .o_output(new_reg)
    );

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