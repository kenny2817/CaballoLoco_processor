import alu_pkg::*;

module pipes_tb;

    localparam REG_WIDTH = 32;
    localparam REG_SELECT = 5;
    localparam INSTR_WIDTH = 32;
    localparam PC_WIDTH = 5;

    logic clk = 0, rst, nop;

    // Register select paths
    logic [PC_WIDTH -1 : 0] pc_F, pc_D;
    logic [REG_SELECT -1 : 0] reg_a_select_D, reg_a_select_A;
    logic [REG_SELECT -1 : 0] reg_b_select_D, reg_b_select_A;
    logic [REG_SELECT -1 : 0] reg_c_select_D, reg_c_select_A, reg_c_select_M, reg_c_select_W;

    // Data paths
    logic [INSTR_WIDTH -1 : 0] instruction_F, instruction_D;
    logic [REG_WIDTH -1 : 0] reg_a_D, reg_a_A;
    logic [REG_WIDTH -1 : 0] reg_b_D, reg_b_A, reg_b_M;
    logic [REG_WIDTH -1 : 0] offset_D, offset_A;
    logic [REG_WIDTH -1 : 0] alu_data_A, alu_data_M, alu_data_W;
    logic [REG_WIDTH -1 : 0] mem_data_M, mem_data_W;

    // Control signals
    logic       is_write_D, is_write_A, is_write_M, is_write_W;
    logic       is_load_D, is_load_A, is_load_M, is_load_W;
    logic       is_store_D, is_store_A, is_store_M;
    logic       cmp_data_D;
    alu_op_e    alu_op_D, alu_op_A;

    pipe_D #(
        .INSTR_WIDTH(INSTR_WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) dut_D (
        .clk(clk),
        .rst(rst),
        .enable(!nop),
        .flush(cmp_data_D),
        .i_instruction(instruction_F),
        .i_pc(pc_F),
        .o_instruction(instruction_D),
        .o_pc(pc_D)
    );

    pipe_A #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) dut_A (
        .clk(clk),
        .rst(rst),
        .enable(!nop),

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

    pipe_M #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) dut_M (
        .clk(clk),
        .rst(rst),
        .enable(!nop),

        .i_reg_b(reg_b_A),
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

    pipe_W #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) dut_W (
        .clk(clk),
        .rst(rst),
        .enable(!nop),

        .i_mem_data(mem_data_W),
        .i_alu_data(alu_data_M),
        .i_reg_c_select(reg_c_select_M),
        .i_is_write(is_write_M),
        .i_is_load(is_load_M),

        .o_mem_data(mem_data_M),
        .o_alu_data(alu_data_W),
        .o_reg_c_select(reg_c_select_W),
        .o_is_write(is_write_W),
        .o_is_load(is_load_W)
    );

    always #5 clk = ~clk;

    initial begin
        // test TODO
        rst = 1; nop = 0; #10;
        rst = 0; #10;
        $finish;
    end

    initial $monitor(
        "t:%4t | rst:%b | nop:%b | flush:%b || instr:%h %h | pc:%h %h |",
        $time, rst, nop, cmp_data_D, 
        instruction_F, instruction_D, pc_F, pc_D
    );

endmodule