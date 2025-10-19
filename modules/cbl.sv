
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
    logic [INSTR_SELECT -1 : 0] pc_F, pc_D, new_pc;
    logic [REG_SELECT -1 : 0] reg_a_select_D, reg_a_select_A;
    logic [REG_SELECT -1 : 0] reg_b_select_D, reg_b_select_A;
    logic [REG_SELECT -1 : 0] reg_c_select_D, reg_c_select_A, reg_c_select_M, reg_c_select_W;

    // Data paths
    logic [REG_WIDTH -1 : 0] instruction_F, instruction_D;
    wire  [REG_WIDTH -1 : 0] regs_D [NUM_REG];
    logic [REG_WIDTH -1 : 0] reg_a_D, reg_a_A;
    logic [REG_WIDTH -1 : 0] reg_b_D, reg_b_A, reg_b_M, reg_b_forwarded;
    logic [REG_WIDTH -1 : 0] a, b;
    logic [REG_WIDTH -1 : 0] offset_D, offset_A;
    logic [REG_WIDTH -1 : 0] alu_data_A, alu_data_M, alu_data_W;
    logic [REG_WIDTH -1 : 0] mem_data_M, mem_data_W;
    logic [REG_WIDTH -1 : 0] new_reg;

    // Control signals
    logic       is_write_D, is_write_A, is_write_M, is_write_W;
    logic       is_load_D, is_load_A, is_load_M, is_load_W;
    logic       is_store_D, is_store_A, is_store_M;
    logic       is_cmp_D;
    logic       cmp_data_D;
    alu_op_e    alu_op_D, alu_op_A;
    cmp_op_e    cmp_op_D;

    // Hazard and Forwarding signals
    logic       nop;
    logic       forward_a_D, forward_b_D, select_forward_a_D, select_forward_b_D;
    logic       forward_a_A, forward_b_A, select_forward_a_A, select_forward_b_A;

// PROGRAM COUNTER
    register_mono #(
        .DATA_WIDTH(INSTR_SELECT)
    ) PC (
        .clk(clk),
        .rst(rst),
        .i_write_enable(!nop),
        .i_write_data(new_pc),
        .o_read_data(pc_F)
    );

 assign new_pc = cmp_data_D ? (pc_D + offset_D[INSTR_SELECT -1 : 0]) : (pc_F + 1);

    // INSTRUCTIONS
    register_bank_mono #( 
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_INSTR)
    ) INSTRUCTIONS (
        .clk(clk),
        .rst(rst),
        .i_write_enable(NO),
        .i_select(pc_F),
        .i_write_data('x),
        .o_read_data(instruction_F)
    );

// PIPE_D ===============================================================
    pipe_D #(
        .INSTR_WIDTH(REG_WIDTH),
        .PC_WIDTH(INSTR_SELECT)
    ) PIPE_D (
        .clk(clk),
        .rst(rst),
        .enable(!nop),
        .flush(cmp_data_D),

        .i_instruction(instruction_F),
        .i_pc(pc_F),

        .o_instruction(instruction_D),
        .o_pc(pc_D)
    );

    // OPCODE DECODER
    opd_32 #(
        .NUM_REG(NUM_REG)
    ) OPD_32 (
        .i_instruction(instruction_D),
        .i_nop(nop),

        .o_select_a(reg_a_select_D),
        .o_select_b(reg_b_select_D),
        .o_select_c(reg_c_select_D),
        .o_is_write(is_write_D),
        .o_is_load(is_load_D),
        .o_is_store(is_store_D),
        .o_is_cmp(is_cmp_D),
        .o_cmp_op(cmp_op_D),
        .o_alu_op(alu_op_D),
        .o_offset(offset_D)
    );

    // REGISTERS
    register_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_REG)
    ) REGISTERS (
        .clk(clk),
        .rst(rst),
        .i_write_enable(is_write_W),
        .i_write_select(reg_c_select_W),
        .i_write_data(new_reg),
        .o_read_data(regs_D)
    );

    // REGISTER A
    assign reg_a_D = (forward_a_D) ? 
        (select_forward_a_D ? new_reg : alu_data_M) : 
        regs_D[reg_a_select_D];
    

    // REGISTER B
    assign reg_b_D = (forward_b_D) ?
        (select_forward_b_D ? new_reg : alu_data_M) : 
        regs_D[reg_b_select_D];

    // COMPARATOR
    cmp #(
        .DATA_WIDTH(REG_WIDTH)
    ) CMP (
        .i_elemA(reg_a_D),
        .i_elemB(reg_b_D),
        .i_op(cmp_op_D),
        .o_output(cmp_data_D)
    );

// PIPE_A ===============================================================
    pipe_A #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_A (
        .clk(clk),
        .rst(rst),
        .enable(YES),
        
        .i_reg_a(reg_a_D),
        .i_reg_b(reg_b_D),
        .i_offset(offset_D),
        .i_reg_a_select(reg_a_select_D),
        .i_reg_b_select(reg_b_select_D),
        .i_reg_c_select(reg_c_select_D),
        .i_is_write(is_write_D),
        .i_is_load(is_load_D),
        .i_is_store(is_store_D),
        .i_alu_op(alu_op_D),

        .o_reg_a(reg_a_A),
        .o_reg_b(reg_b_A),
        .o_offset(offset_A),
        .o_reg_a_select(reg_a_select_A),
        .o_reg_b_select(reg_b_select_A),
        .o_reg_c_select(reg_c_select_A),
        .o_is_write(is_write_A),
        .o_is_load(is_load_A),
        .o_is_store(is_store_A),
        .o_alu_op(alu_op_A)
    );

    // MUX reg_a-FORWARDING-PC
    assign a = (forward_a_A) ? (select_forward_a_A ? new_reg : alu_data_M) : reg_a_A;
    
    // MUX reg_b-FORWARDING-OFFSET
    assign reg_b_forwarded = (forward_b_A) ? (select_forward_b_A ? new_reg : alu_data_M) : reg_b_A;
    assign b = (is_store_A | is_load_A) ? offset_A : reg_b_forwarded;

    // ALU
    alu #(
        .DATA_WIDTH(REG_WIDTH)
    ) ALU (
        .i_elemA(a),
        .i_elemB(b),
        .i_op(alu_op_A),
        .o_output(alu_data_A)
    );

// PIPE_M ===============================================================
    pipe_M #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_M (
        .clk(clk),
        .rst(rst),
        .enable(YES),

        .i_reg_b(reg_b_forwarded),
        .i_alu_data(alu_data_A),
        .i_reg_c_select(reg_c_select_A),
        .i_is_write(is_write_A),
        .i_is_load(is_load_A),
        .i_is_store(is_store_A),

        .o_reg_b(reg_b_M),
        .o_alu_data(alu_data_M),
        .o_reg_c_select(reg_c_select_M),
        .o_is_write(is_write_M),
        .o_is_load(is_load_M),
        .o_is_store(is_store_M)
    );

    // MEMORY
    register_bank_mono #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_MEM)
    ) MEM (
        .clk(clk),
        .rst(rst),
        .i_write_enable(is_store_M),
        .i_select(alu_data_M[MEM_SELECT -1 : 0]),
        .i_write_data(reg_b_M),
        .o_read_data(mem_data_M)
    );

// PIPE_W ===============================================================
    pipe_W #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_W (
        .clk(clk),
        .rst(rst),
        .enable(YES),

        .i_mem_data(mem_data_M),
        .i_alu_data(alu_data_M),
        .i_reg_c_select(reg_c_select_M),
        .i_is_write(is_write_M),
        .i_is_load(is_load_M),

        .o_mem_data(mem_data_W),
        .o_alu_data(alu_data_W),
        .o_reg_c_select(reg_c_select_W),
        .o_is_write(is_write_W),
        .o_is_load(is_load_W)
    );

    // MUX ALU-MEM
    assign new_reg = is_load_W ? mem_data_W : alu_data_W;

// CTRL UNITS ==========================================================
    // HAZARD UNIT
    haz #(
        .REG_SELECT(REG_SELECT)
    ) HAZARD_UNIT (
        .i_is_cmp_D(is_cmp_D),
        .i_is_write_A(is_write_A),
        .i_is_load_D(is_load_D),
        .i_is_load_A(is_load_A),
        .i_reg_a_select_D(reg_a_select_D),
        .i_reg_b_select_D(reg_b_select_D),
        .i_reg_c_select_A(reg_c_select_A),

        .o_nop(nop)
    );

    // FORWARDING reg_a & reg_b
    fwd #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) FWD_D (
        .i_reg_a_select(reg_a_select_D),
        .i_reg_b_select(reg_b_select_D),

        .i_is_write_M(is_write_M),
        .i_reg_c_select_M(reg_c_select_M),
        .i_is_write_W(is_write_W),
        .i_reg_c_select_W(reg_c_select_W),

        .o_forward_a(forward_a_D),
        .o_select_forward_a(select_forward_a_D),
        .o_forward_b(forward_b_D),
        .o_select_forward_b(select_forward_b_D)
    );

    // FORWARDING a & b
    fwd #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) FWD_A (
        .i_reg_a_select(reg_a_select_A),
        .i_reg_b_select(reg_b_select_A),

        .i_is_write_M(is_write_M),
        .i_reg_c_select_M(reg_c_select_M),
        .i_is_write_W(is_write_W),
        .i_reg_c_select_W(reg_c_select_W),

        .o_forward_a(forward_a_A),
        .o_select_forward_a(select_forward_a_A),
        .o_forward_b(forward_b_A),
        .o_select_forward_b(select_forward_b_A)
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
        dut.MEM.data[0], dut.MEM.data[1], dut.MEM.data[2], dut.MEM.data[3], dut.MEM.data[4], dut.pc_F, dut.pc_D, dut.instruction_D, 
        dut.a, dut.b, dut.alu_data_A, 
        dut.is_load_D, dut.is_load_A, dut.is_load_M, dut.is_load_W, 
        dut.is_store_D, dut.is_store_A, dut.is_store_M,
        dut.nop, 
        dut.forward_a_D, dut.select_forward_a_D, dut.forward_b_D, dut.select_forward_b_D,
        dut.forward_a_A, dut.select_forward_a_A, dut.forward_b_A, dut.select_forward_b_A, dut.alu_data_A, dut.new_reg
    );

endmodule