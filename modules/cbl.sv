
import cmp_pkg::*;
import alu_pkg::*;
import opcodes_pkg::*;

module cbl #(
    parameter NUM_REG,
    parameter REG_WIDTH,
    parameter NUM_INSTR,
    parameter NUM_MEM
) (
    input logic clk,
    input logic rst
);

// LOCAL PARAMETERS =============================================================

    wire YES = 1'b1;
    wire NO = 1'b0;

    localparam REG_SELECT = $clog2(NUM_REG);
    localparam INSTR_SELECT = $clog2(NUM_INSTR);
    localparam MEM_SELECT = $clog2(NUM_MEM);

// CABLE MANAGEMENT ======================================================
    // Register select paths
    logic [INSTR_SELECT -1 : 0] pc_0, pc_1, new_pc;
    logic [REG_SELECT -1 : 0] reg_a_select_0, reg_a_select_1;
    logic [REG_SELECT -1 : 0] reg_b_select_0, reg_b_select_1;
    logic [REG_SELECT -1 : 0] reg_c_select_0, reg_c_select_1, reg_c_select_2, reg_c_select_3;

    // Data paths
    logic [REG_WIDTH -1 : 0] instruction_0, instruction_1;
    wire  [REG_WIDTH -1 : 0] regs_0 [NUM_REG];
    logic [REG_WIDTH -1 : 0] reg_a_0, reg_a_1;
    logic [REG_WIDTH -1 : 0] reg_b_0, reg_b_1, reg_b_2, reg_b_forwarded;
    logic [REG_WIDTH -1 : 0] a, b;
    logic [REG_WIDTH -1 : 0] offset_0, offset_1;
    logic [REG_WIDTH -1 : 0] alu_data_0, alu_data_1, alu_data_2;
    logic [REG_WIDTH -1 : 0] mem_data_0, mem_data_1;
    logic [REG_WIDTH -1 : 0] new_reg;

    // Control signals
    logic       is_write_0, is_write_1, is_write_2, is_write_3;
    logic       is_load_0, is_load_1, is_load_2, is_load_3;
    logic       is_store_0, is_store_1, is_store_2;
    logic       is_cmp_0;
    logic       cmp_data_0;
    alu_op_e    alu_op_0, alu_op_1;
    cmp_op_e    cmp_op_0;

    // Hazard and Forwarding signals
    logic       nop;
    logic       forward_a_0, forward_b_0, select_forward_a_0, select_forward_b_0;
    logic       forward_a_1, forward_b_1, select_forward_a_1, select_forward_b_1;

// PROGRAM COUNTER
    register_mono #(
        .DATA_WIDTH(INSTR_SELECT)
    ) PC (
        .clk(clk),
        .rst(rst),
        .i_write_enable(!nop),
        .i_write_data(new_pc),
        .o_read_data(pc_0)
    );

    assign new_pc = cmp_data_0 ? (pc_1 + offset_0[INSTR_SELECT -1 : 0]) : (pc_0 + 1);

    // INSTRUCTIONS
    register_bank_mono #( 
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_INSTR)
    ) INSTRUCTIONS (
        .clk(clk),
        .rst(rst),
        .i_write_enable(NO),
        .i_select(pc_0),
        .i_write_data('x),
        .o_read_data(instruction_0)
    );

// PIPE_0 ===============================================================
    pipe_0 #(
        .INSTR_WIDTH(REG_WIDTH),
        .PC_WIDTH(INSTR_SELECT)
    ) PIPE_0 (
        .clk(clk),
        .rst(rst),
        .enable(!nop),
        .flush(cmp_data_0),

        .i_instruction(instruction_0),
        .i_pc(pc_0),

        .o_instruction(instruction_1),
        .o_pc(pc_1)
    );

    // OPCODE DECODER
    opd_32 #(
        .NUM_REG(NUM_REG)
    ) OPD_32 (
        .i_instruction(instruction_1),
        .i_nop(nop),

        .o_select_a(reg_a_select_0),
        .o_select_b(reg_b_select_0),
        .o_select_c(reg_c_select_0),
        .o_is_write(is_write_0),
        .o_is_load(is_load_0),
        .o_is_store(is_store_0),
        .o_is_cmp(is_cmp_0),
        .o_cmp_op(cmp_op_0),
        .o_alu_op(alu_op_0),
        .o_offset(offset_0)
    );

    // REGISTERS
    register_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_REG)
    ) REGISTERS (
        .clk(clk),
        .rst(rst),
        .i_write_enable(is_write_3),
        .i_write_select(reg_c_select_3),
        .i_write_data(new_reg),
        .o_read_data(regs_0)
    );

    // REGISTER A
    assign reg_a_0 = (forward_a_0) ? 
        (select_forward_a_0 ? new_reg : alu_data_1) : 
        regs_0[reg_a_select_0];
    

    // REGISTER B
    assign reg_b_0 = (forward_b_0) ?
        (select_forward_b_0 ? new_reg : alu_data_1) : 
        regs_0[reg_b_select_0];

    // COMPARATOR
    cmp #(
        .DATA_WIDTH(REG_WIDTH)
    ) CMP (
        .i_elemA(reg_a_0),
        .i_elemB(reg_b_0),
        .i_op(cmp_op_0),
        .o_output(cmp_data_0)
    );

// PIPE_1 ===============================================================
    pipe_1 #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_1 (
        .clk(clk),
        .rst(rst),
        .enable(YES),
        
        .i_reg_a(reg_a_0),
        .i_reg_b(reg_b_0),
        .i_offset(offset_0),
        .i_reg_a_select(reg_a_select_0),
        .i_reg_b_select(reg_b_select_0),
        .i_reg_c_select(reg_c_select_0),
        .i_is_write(is_write_0),
        .i_is_load(is_load_0),
        .i_is_store(is_store_0),
        .i_alu_op(alu_op_0),

        .o_reg_a(reg_a_1),
        .o_reg_b(reg_b_1),
        .o_offset(offset_1),
        .o_reg_a_select(reg_a_select_1),
        .o_reg_b_select(reg_b_select_1),
        .o_reg_c_select(reg_c_select_1),
        .o_is_write(is_write_1),
        .o_is_load(is_load_1),
        .o_is_store(is_store_1),
        .o_alu_op(alu_op_1)
    );

    // MUX reg_a-FORWARDING-PC
    assign a = (forward_a_1) ? (select_forward_a_1 ? new_reg : alu_data_1) : reg_a_1;
    
    // MUX reg_b-FORWARDING-OFFSET
    assign reg_b_forwarded = (forward_b_1) ? (select_forward_b_1 ? new_reg : alu_data_1) : reg_b_1;
    assign b = (is_store_1 | is_load_1) ? offset_1 : reg_b_forwarded;

    // ALU
    alu #(
        .DATA_WIDTH(REG_WIDTH)
    ) ALU (
        .i_elemA(a),
        .i_elemB(b),
        .i_op(alu_op_1),
        .o_output(alu_data_0)
    );

// PIPE_2 ===============================================================
    pipe_2 #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_2 (
        .clk(clk),
        .rst(rst),
        .enable(YES),

        .i_reg_b(reg_b_forwarded),
        .i_alu_data(alu_data_0),
        .i_reg_c_select(reg_c_select_1),
        .i_is_write(is_write_1),
        .i_is_load(is_load_1),
        .i_is_store(is_store_1),

        .o_reg_b(reg_b_2),
        .o_alu_data(alu_data_1),
        .o_reg_c_select(reg_c_select_2),
        .o_is_write(is_write_2),
        .o_is_load(is_load_2),
        .o_is_store(is_store_2)
    );

    // MEMORY
    register_bank_mono #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_MEM)
    ) MEM (
        .clk(clk),
        .rst(rst),
        .i_write_enable(is_store_2),
        .i_select(alu_data_1[MEM_SELECT -1 : 0]),
        .i_write_data(reg_b_2),
        .o_read_data(mem_data_0)
    );

// PIPE_3 ===============================================================
    pipe_3 #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_3 (
        .clk(clk),
        .rst(rst),
        .enable(YES),

        .i_mem_data(mem_data_0),
        .i_alu_data(alu_data_1),
        .i_reg_c_select(reg_c_select_2),
        .i_is_write(is_write_2),
        .i_is_load(is_load_2),

        .o_mem_data(mem_data_1),
        .o_alu_data(alu_data_2),
        .o_reg_c_select(reg_c_select_3),
        .o_is_write(is_write_3),
        .o_is_load(is_load_3)
    );

    // MUX ALU-MEM
    assign new_reg = is_load_3 ? mem_data_1 : alu_data_2;

// CTRL UNITS ==========================================================
    // HAZARD UNIT
    haz #(
        .REG_SELECT(REG_SELECT)
    ) HAZARD_UNIT (
        .i_is_cmp_0(is_cmp_0),
        .i_is_write_1(is_write_1),
        .i_is_load_0(is_load_0),
        .i_is_load_1(is_load_1),
        .i_reg_a_select_0(reg_a_select_0),
        .i_reg_b_select_0(reg_b_select_0),
        .i_reg_c_select_1(reg_c_select_1),

        .o_nop(nop)
    );

    // FORWARDING reg_a & reg_b
    fwd #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) FWD_0 (
        .i_reg_a_select(reg_a_select_0),
        .i_reg_b_select(reg_b_select_0),

        .i_is_write_2(is_write_2),
        .i_reg_c_select_2(reg_c_select_2),
        .i_is_write_3(is_write_3),
        .i_reg_c_select_3(reg_c_select_3),

        .o_forward_a(forward_a_0),
        .o_select_forward_a(select_forward_a_0),
        .o_forward_b(forward_b_0),
        .o_select_forward_b(select_forward_b_0)
    );

    // FORWARDING a & b
    fwd #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) FWD_1 (
        .i_reg_a_select(reg_a_select_1),
        .i_reg_b_select(reg_b_select_1),

        .i_is_write_2(is_write_2),
        .i_reg_c_select_2(reg_c_select_2),
        .i_is_write_3(is_write_3),
        .i_reg_c_select_3(reg_c_select_3),

        .o_forward_a(forward_a_1),
        .o_select_forward_a(select_forward_a_1),
        .o_forward_b(forward_b_1),
        .o_select_forward_b(select_forward_b_1)
    );

endmodule

module cbl_tb;

    // Parameters
    localparam NUM_REG = 10;
    localparam REG_WIDTH = 32;
    localparam NUM_INSTR = 11;
    localparam NUM_MEM = 5;

    // Local parameters
    localparam REG_SELECT = $clog2(NUM_REG);
    localparam logic [REG_SELECT-1:0] REG_0 = 0;
    localparam logic [REG_SELECT-1:0] REG_1 = 1;
    localparam logic [REG_SELECT-1:0] REG_2 = 2;
    localparam logic [REG_SELECT-1:0] REG_3 = 3;
    localparam logic [REG_SELECT-1:0] REG_4 = 4;

    // Signals
    logic clk = 0;
    logic rst;

    // DUT
    cbl #(
        .NUM_REG(NUM_REG),
        .REG_WIDTH(REG_WIDTH),
        .NUM_INSTR(NUM_INSTR),
        .NUM_MEM(NUM_MEM)
    ) dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    always #5 clk = ~clk;


    initial begin
        $monitoroff;
        rst = 1; #1; rst = 0; #1;
        dut.MEM.data[0] = 1; dut.MEM.data[1] = 2; 
        dut.INSTRUCTIONS.data[0] = {LW_OP,  REG_0, REG_0, REG_4, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[1] = {LW_OP,  REG_0, REG_0, REG_0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[2] = {LW_OP,  REG_0, REG_0, REG_1, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[3] = {ADD_OP, REG_1, REG_0, REG_2, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[4] = {SW_OP,  REG_1, REG_2, REG_0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[5] = {BEQ_OP, REG_2, REG_2, REG_0, {{(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT -2){1'b0}}, 2'd1}};
        dut.INSTRUCTIONS.data[9] = {ADD_OP, REG_1, REG_0, REG_3, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        @(posedge clk);
        $monitoron;
        #135;
        $finish;
    end
    initial begin
        $dumpfile("cbl.vcd");
        $dumpvars(0, cbl_tb);
    end

    initial $monitor(
        "t:%3t | regs:%3d %3d %3d %3d %3d | mem:%3d %3d %3d %3d %3d | pc:%2d %2d | ist:%b | alu:%4d %4d : %4d | ld:%b %b %b %b | st:%b %b %b | nop:%b | f0:%b %b %b %b | f1:%b %b %b %b | %2d %2d |", 
        $time, dut.REGISTERS.data[0], dut.REGISTERS.data[1], dut.REGISTERS.data[2], dut.REGISTERS.data[3], dut.REGISTERS.data[4], 
        dut.MEM.data[0], dut.MEM.data[1], dut.MEM.data[2], dut.MEM.data[3], dut.MEM.data[4], dut.pc_0, dut.pc_1, dut.instruction_1, 
        dut.a, dut.b, dut.alu_data_0, 
        dut.is_load_0, dut.is_load_1, dut.is_load_2, dut.is_load_3, 
        dut.is_store_0, dut.is_store_1, dut.is_store_2,
        dut.nop, 
        dut.forward_a_0, dut.select_forward_a_0, dut.forward_b_0, dut.select_forward_b_0,
        dut.forward_a_1, dut.select_forward_a_1, dut.forward_b_1, dut.select_forward_b_1, dut.alu_data_1, dut.new_reg
    );

endmodule