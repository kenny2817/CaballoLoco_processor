
import cmp_pkg::*;
import alu_pkg::*;
import opcodes_pkg::*;


module cbs_tb;

    localparam NUM_REG = 5;
    localparam REG_WIDTH = 32;
    localparam NUM_INSTR = 10;
    localparam NUM_MEM = 5;
    localparam REG_SELECT = $clog2(NUM_REG);
    localparam MEM_SELECT = $clog2(NUM_MEM);

    logic clk = 0, rst;

    cbs #(
        .NUM_REG(NUM_REG),
        .REG_WIDTH(REG_WIDTH),
        .NUM_INSTR(NUM_INSTR),
        .NUM_MEM(NUM_MEM)
    ) dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    localparam REG_0 = 3'd0; 
    localparam REG_1 = 3'd1; 
    localparam REG_2 = 3'd2; 
    localparam REG_3 = 3'd3; 
    localparam REG_4 = 3'd4; 

    initial begin
        $monitoroff;
        rst = 1; #1; rst = 0;
        dut.MEM.data[0] = 32'd1; dut.MEM.data[1] = 32'd2;
        dut.INSTRUCTIONS.data[0] = {LW_OP,  REG_0, REG_0, REG_4, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[1] = {LW_OP,  REG_0, REG_0, REG_0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[2] = {LW_OP,  REG_0, REG_0, REG_1, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[3] = {ADD_OP, REG_1, REG_0, REG_2, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[4] = {SW_OP,  REG_2, REG_2, REG_0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[5] = {BEQ_OP, REG_2, REG_2, REG_0, {{(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT -2){1'b0}}, 2'd1}};
        dut.INSTRUCTIONS.data[8] = {ADD_OP, REG_1, REG_0, REG_2, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        $monitoron;
        #95;
        $finish;
    end


    initial begin
        $dumpfile("cbl.vcd");
        $dumpvars(0, cbs_tb);
    end

    initial $monitor("t=%3t | pc= %2d | ist=%b | reg_a=%3d a=%3d | reg_b=%3d b=%3d | reg_c=%3d | write=%b | alu=%7d | regs=%3d %3d %3d %3d %3d | mem=%3d %3d %3d %3d %3d | new_reg=%3d | offset=%3d |", 
        $time, dut.pc,dut.instruction, dut.reg_a, dut.a, dut.reg_b, dut.b, dut.reg_c_select, dut.is_write, dut.alu_data,
        dut.REGISTERS.data[0], dut.REGISTERS.data[1], dut.REGISTERS.data[2], dut.REGISTERS.data[3], dut.REGISTERS.data[4], 
        dut.MEM.data[0], dut.MEM.data[1], dut.MEM.data[2], dut.MEM.data[3], dut.MEM.data[4],
        dut.new_reg, dut.offset
    );

endmodule