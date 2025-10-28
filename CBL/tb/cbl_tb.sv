
import cmp_pkg::*;
import alu_pkg::*;
import opcodes_pkg::*;


module cbl_tb;

    // Parameters
    localparam NUM_REG = 10;
    localparam REG_WIDTH = 32;
    localparam NUM_INSTR = 32;
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