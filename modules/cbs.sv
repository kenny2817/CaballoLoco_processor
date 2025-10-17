
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
    input logic rst,
    input logic [REG_WIDTH -1 : 0] i_instructions [NUM_INSTR]
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

    assign o_mem_store_enable = is_store;
    assign o_mem_store_select = alu_data;
    assign o_mem_store_word = reg_b;
    // PROGRAM COUNTER
    register_mono #(
        .DATA_WIDTH(INSTR_SELECT)
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
        .i_offset(alu_data[INSTR_SELECT -1 : 0]),
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

    assign a = (is_cmp) ? {{(REG_WIDTH - INSTR_SELECT){1'b0}}, pc} : reg_a;

    // REGISTER B
    mux #(
        .NUM_INPUTS(NUM_REG),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_B_0 (
        .i_data_bus(regs),
        .i_select(reg_b_select),
        .o_output(reg_b)
    );

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
    register_bank_mono #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_MEM)
    ) MEM (
        .clk(clk),
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


module cbs_tb;

    localparam NUM_REG = 5;
    localparam REG_WIDTH = 32;
    localparam NUM_INSTR = 10;
    localparam NUM_MEM = 5;
    localparam REG_SELECT = $clog2(NUM_REG);
    localparam MEM_SELECT = $clog2(NUM_MEM);

    logic clk = 0, rst, display = 0;
    logic [REG_WIDTH -1 : 0] instructions [NUM_INSTR];

    cbs #(
        .NUM_REG(NUM_REG),
        .REG_WIDTH(REG_WIDTH),
        .NUM_INSTR(NUM_INSTR),
        .NUM_MEM(NUM_MEM)
    ) dut (
        .clk(clk),
        .rst(rst),
        .i_instructions(instructions)
    );

    always #5 clk = ~clk;
    always #10 display = ~display;

    localparam REG_0 = 3'd0; 
    localparam REG_1 = 3'd1; 
    localparam REG_2 = 3'd2; 

    initial begin
        $monitoroff;
        dut.MEM.data[0] = 32'd1;
        dut.MEM.data[1] = 32'd2;
        instructions[0] = {LW_OP,  REG_0, REG_0, REG_0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        instructions[1] = {LW_OP,  REG_0, REG_0, REG_1, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        instructions[2] = {ADD_OP, REG_1, REG_0, REG_2, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        instructions[3] = {SW_OP,  REG_2, REG_2, REG_0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        instructions[4] = {BEQ_OP, REG_2, REG_2, REG_0, {{(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT -2){1'b0}}, 2'd1}};
        instructions[8] = {ADD_OP, REG_1, REG_0, REG_2, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        rst = 1; #10;
        rst = 0;
        $monitoron;
        #101;

        $finish;
    end

    initial $monitor("t=%3t | pc= %2d | ist=%b | reg_a=%3d a=%3d | reg_b=%3d b=%3d | reg_c=%3d | write=%b | alu=%7d | regs=%3d %3d %3d %3d %3d | mem=%3d %3d %3d %3d %3d | new_reg=%3d | offset=%3d | sele_instr=%d", 
        $time, dut.pc,dut.instruction, dut.reg_a, dut.a, dut.reg_b, dut.b, dut.reg_c_select, dut.is_write, dut.alu_data,
        dut.REGISTERS.data[0], dut.REGISTERS.data[1], dut.REGISTERS.data[2], dut.REGISTERS.data[3], dut.REGISTERS.data[4], 
        dut.MEM.data[0], dut.MEM.data[1], dut.MEM.data[2], dut.MEM.data[3], dut.MEM.data[4],
        dut.new_reg, dut.offset, dut.INSTR_SELECT
    );

endmodule