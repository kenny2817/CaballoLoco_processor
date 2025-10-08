`define UP '1

module cbl #(
    parameter NUM_REG,
    parameter REG_WIDTH,
    parameter NUM_INSTR,
    parameter INSTR_WIDTH,
    parameter NUM_MEM
    localparam PC_WIDTH = $clog2(NUM_INSTR);
) (
    input logic clk,
    input logic [NUM_INSTR * INSTR_WIDTH -1 : 0] i_instructions,
    // inout logic [NUM_MEM * REG_WIDTH -1 : 0] io_mem
);

// CABLE MANAGEMENT
    logic [PC_WIDTH -1 : 0] pc_0, [PC_WIDTH -1 : 0] pc_1, [PC_WIDTH -1 : 0] pc_2;
    logic [INSTR_WIDTH -1 : 0] instruction_0, [INSTR_WIDTH -1 : 0] instruction_1;
    logic [NUM_REG * REG_WIDTH - 1 : 0] reg;
    logic [REG_WIDTH -1 : 0] reg_A_0, [REG_WIDTH -1 : 0] reg_A_1;
    logic [REG_WIDTH -1 : 0] reg_B_0, [REG_WIDTH -1 : 0] reg_B_1;
    logic [REG_WIDTH -1 : 0] a_0, [REG_WIDTH -1 : 0] a_1;
    logic [REG_WIDTH -1 : 0] b_0, [REG_WIDTH -1 : 0] b_1;
    logic [REG_WIDTH -1 : 0] alu_0, [REG_WIDTH -1 : 0] alu_1;
    logic [NUM_MEM * REG_WIDTH -1 : 0] mem_0, [REG_WIDTH -1 : 0] mem_1;
    logic [REG_WIDTH -1 : 0] reg_data_0, [REG_WIDTH -1 : 0] reg_data_1;

// PC
    register #(
        .DATA_WIDTH(PC_WIDTH),
        .NUM_REG(1)
    ) PC_0 (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(pc_0),
        .o_read_data(pc_1)
    );

    register #(
        .DATA_WIDTH(PC_WIDTH),
        .NUM_REG(1)
    ) PC_1 (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(pc_1),
        .o_read_data(pc_2)
    );

// INSTRUCTION
    register #(
        .DATA_WIDTH(INSTR_WIDTH),
        .NUM_REG(1)
    ) INSTRUCTION (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(instruction_0),
        .o_read_data(instruction_1)
    );

    mux #(
        .NUM_OUTPUTS(NUM_INSTR)
    ) INSTRUCTION_MUX (
        .i_data_bus(i_instructions),
        .i_select(pc_0),
        .o_output(instruction_0)
    );

// REGISTERS
    register_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_REG)
    ) REGISTERS (
        .clk(clk),
        .i_write_enable(),
        .i_write_select(),
        .i_write_data(reg_data_1),
        .o_read_data(reg)
    );

// REG A
    mux #(
        .NUM_INPUTS(NUM_REG),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_A_0 (
        .i_data_bus(reg),
        .i_select(),
        .o_output(reg_A_0)
    );

    register #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(1)
    )  REG_A (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(reg_A_0),
        .o_read_data(reg_A_1)
    );

// A
    mux #(
        .NUM_INPUTS(),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_A_1 (
        .i_data_bus({reg_A_0, pc_2}),
        .i_select(),
        .o_output(a_0)
    );

    register #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(1)
    ) A (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(a_0),
        .o_read_data(a_1)
    );

// REG B
    mux #(
        .NUM_INPUTS(NUM_REG),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_B_0 (
        .i_data_bus(reg),
        .i_select(),
        .o_output(reg_B_0)
    );

    register #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(1)
    ) REG_B (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(reg_B_0),
        .o_read_data(reg_B_1)
    );

// B
    mux #(
        .NUM_INPUTS(),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_B_1 (
        .i_data_bus({reg_B_0}),
        .i_select(),
        .o_output(b_0)
    );

    register #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(1)
    ) B (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(b_0),
        .o_read_data(b_1)
    );

// ALU
    alu #(
        .DATA_WIDTH(REG_WIDTH)
    ) ALU (
        .i_elemA(a_1),
        .i_elemB(b_1),
        .i_op(),
        .o_output()
    )

    register #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(1)
    ) RES_ALU (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(alu_0),
        .o_read_data(alu_1)
    );

// CMP
    cmp #(
        .DATA_WIDTH(REG_WIDTH)
    ) CMP (
        .i_elemA(reg_A_1),
        .i_elemB(reg_B_1),
        .i_op(),
        .o_output()
    );

// MEM
    register_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_MEM)
    ) MEM (
        .clk(clk),
        .i_write_enable(),
        .i_write_select(alu_0),
        .i_write_data(reg_B_1),
        .o_read_data(mem_0)
    );

    mux #(
        .NUM_INPUTS(NUM_MEM),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_MEM (
        .i_data_bus(mem_0),
        .i_select(alu_1),
        .o_output(mem_1)
    );

    mux #(
        .NUM_INPUTS(2),
        .DATA_WIDTH(REG_WIDTH)
    ) MUX_REG_B_1 (
        .i_data_bus({alu_1, mem_1}),
        .i_select(),
        .o_output(reg_data_0)
    );

    register #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(1)
    ) RES_ALU (
        .clk(clk),
        .i_write_enable(UP),
        .i_write_data(reg_data_0),
        .o_read_data(reg_data_1)
    );

endmodule