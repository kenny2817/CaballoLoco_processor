
import opcodes_pkg::*;
import cmp_pkg::*;
import alu_pkg::*;

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