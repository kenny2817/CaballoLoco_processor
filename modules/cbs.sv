
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


module cbs_tb;

    localparam NUM_REG = 5;
    localparam REG_WIDTH = 32;
    localparam NUM_INSTR = 10;
    localparam NUM_MEM = 5;
    localparam REG_SELECT = $clog2(NUM_REG);
    localparam MEM_SELECT = $clog2(NUM_MEM);

    logic clk = 0, rst, display = 0;
    logic [NUM_INSTR * REG_WIDTH -1 : 0] instructions;

    logic mem_store_enable, write_enable;
    logic [MEM_SELECT -1 : 0] mem_store_select, write_select, fake_select;
    logic [REG_WIDTH -1 : 0] mem_store_word, write_data, fake_word;
    logic [NUM_MEM * REG_WIDTH -1 : 0] mem;

    always_comb begin
        if (rst) begin
            write_enable = 1;
            write_select = fake_select;
            write_data   = fake_word;
        end else begin
            write_enable = mem_store_enable;
            write_select = mem_store_select;
            write_data   = mem_store_word;
        end
    end

    register_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_MEM)
    ) MEM (
        .clk(clk),
        .i_write_enable(write_enable),
        .i_write_select(write_select),
        .i_write_data(write_data),
        .o_read_data(mem)
    );    

    cbs #(
        .NUM_REG(NUM_REG),
        .REG_WIDTH(REG_WIDTH),
        .NUM_INSTR(NUM_INSTR),
        .NUM_MEM(NUM_MEM)
    ) dut (
        .clk(clk),
        .rst(rst),
        .i_instructions(instructions),
        .i_mem(mem),
        .o_mem_store_enable(mem_store_enable),
        .o_mem_store_select(mem_store_select),
        .o_mem_store_word(mem_store_word)
    );

    always #5 clk = ~clk;
    always #10 display = ~display;

    initial begin
        $monitoroff;
        instructions[0 * REG_WIDTH +: REG_WIDTH] = {LW_OP, 3'd0, 3'd0, 3'd0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        instructions[1 * REG_WIDTH +: REG_WIDTH] = {LW_OP, 3'd0, 3'd0, 3'd1, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        instructions[2 * REG_WIDTH +: REG_WIDTH] = {ADD_OP, 3'd1, 3'd0, 3'd2, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        instructions[3 * REG_WIDTH +: REG_WIDTH] = {SW_OP, 3'd2, 3'd2, 3'd0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        instructions[4 * REG_WIDTH +: REG_WIDTH] = {BEQ_OP, 3'd2, 3'd2, 3'd0, {{(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT -2){1'b0}}, 2'd1}};
        instructions[8 * REG_WIDTH +: REG_WIDTH] = {ADD_OP, 3'd1, 3'd0, 3'd2, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        rst = 1;
        fake_select = 0; fake_word = 1; #10;
        fake_select = 1; fake_word = 2; #10;
        rst = 0;
        $monitoron;
        #100;

        $finish;
    end

    initial $monitor("t=%3t | pc= %2d | ist=%b | rega=%b a=%b | regb=%b b=%b | alu=%b | reg=%b | mem %b", 
                $time, dut.pc,dut.instruction, dut.reg_a, dut.a, dut.reg_b, dut.b, dut.alu_data, dut.regs, mem);

endmodule