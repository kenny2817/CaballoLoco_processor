import alu_pkg::*;

module pipe_0 #(
    parameter INSTR_WIDTH,
    parameter PC_WIDTH
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic flush,

    input logic [INSTR_WIDTH -1 : 0] i_instruction,
    input logic [PC_WIDTH -1 : 0] i_pc,

    output logic [INSTR_WIDTH -1 : 0] o_instruction,
    output logic [PC_WIDTH -1 : 0] o_pc
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_pc <= '0;
            o_instruction <= '0;
        end else if (enable) begin
            o_pc <= i_pc;
            o_instruction <= i_instruction;
        end else if (flush) begin
            o_instruction <= '0;
        end
    end
endmodule

module pipe_1 #(
    parameter REG_WIDTH,
    parameter REG_SELECT
) (
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [REG_WIDTH -1 : 0] i_reg_a,
    input logic [REG_WIDTH -1 : 0] i_reg_b,
    input logic [REG_WIDTH -1 : 0] i_offset,
    input logic [REG_SELECT -1 : 0] i_reg_a_select,
    input logic [REG_SELECT -1 : 0] i_reg_b_select,
    input logic [REG_SELECT -1 : 0] i_reg_c_select,
    input logic i_is_write,
    input logic i_is_load,
    input logic i_is_store,
    input alu_op_e i_alu_op,

    output logic [REG_WIDTH -1 : 0] o_reg_a,
    output logic [REG_WIDTH -1 : 0] o_reg_b,
    output logic [REG_WIDTH -1 : 0] o_offset,
    output logic [REG_SELECT -1 : 0] o_reg_a_select,
    output logic [REG_SELECT -1 : 0] o_reg_b_select,
    output logic [REG_SELECT -1 : 0] o_reg_c_select,
    output logic o_is_write,
    output logic o_is_load,
    output logic o_is_store,
    output alu_op_e o_alu_op
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_reg_a <= '0;
            o_reg_b <= '0;
            o_offset <= '0;
            o_reg_a_select <= '0;
            o_reg_b_select <= '0;
            o_reg_c_select <= '0;
            o_is_write <= 1'b0;
            o_is_load <= 1'b0;
            o_is_store <= 1'b0;
            o_alu_op <= ADD;
        end else if (enable) begin
            o_reg_a <= i_reg_a;
            o_reg_b <= i_reg_b;
            o_offset <= i_offset;
            o_reg_a_select <= i_reg_a_select;
            o_reg_b_select <= i_reg_b_select;
            o_reg_c_select <= i_reg_c_select;
            o_is_write <= i_is_write;
            o_is_load <= i_is_load;
            o_is_store <= i_is_store;
            o_alu_op <= i_alu_op;
        end
    end
endmodule

module pipe_2 #(
    parameter REG_WIDTH,
    parameter REG_SELECT
) (
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [REG_WIDTH -1 : 0] i_reg_b,
    input logic [REG_WIDTH -1 : 0] i_alu_data,
    input logic [REG_SELECT -1 : 0] i_reg_c_select,
    input logic i_is_write,
    input logic i_is_load,
    input logic i_is_store,
    
    output logic [REG_WIDTH -1 : 0] o_reg_b,
    output logic [REG_WIDTH -1 : 0] o_alu_data,
    output logic [REG_SELECT -1 : 0] o_reg_c_select,
    output logic o_is_write,
    output logic o_is_load,
    output logic o_is_store
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_reg_b <= '0;
            o_alu_data <= '0;
            o_reg_c_select <= '0;
            o_is_write <= 1'b0;
            o_is_load <= 1'b0;
            o_is_store <= 1'b0;
        end else if (enable) begin
            o_reg_b <= i_reg_b;
            o_alu_data <= i_alu_data;
            o_reg_c_select <= i_reg_c_select;
            o_is_write <= i_is_write;
            o_is_load <= i_is_load;
            o_is_store <= i_is_store;
        end
    end

endmodule

module pipe_3 #(
    parameter REG_WIDTH,
    parameter REG_SELECT
) (
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [REG_WIDTH -1 : 0] i_mem_data,
    input logic [REG_WIDTH -1 : 0] i_alu_data,
    input logic [REG_SELECT -1 : 0] i_reg_c_select,
    input logic i_is_write,
    input logic i_is_load,
    
    output logic [REG_WIDTH -1 : 0] o_mem_data,
    output logic [REG_WIDTH -1 : 0] o_alu_data,
    output logic [REG_SELECT -1 : 0] o_reg_c_select,
    output logic o_is_write,
    output logic o_is_load
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            o_mem_data <= '0;
            o_alu_data <= '0;
            o_reg_c_select <= '0;
            o_is_write <= 1'b0;
            o_is_load <= 1'b0;
        end else if (enable) begin
            o_mem_data <= i_mem_data;
            o_alu_data <= i_alu_data;
            o_reg_c_select <= i_reg_c_select;
            o_is_write <= i_is_write;
            o_is_load <= i_is_load;
        end
    end
    
endmodule

module pipes_tb;

    localparam REG_WIDTH = 32;
    localparam REG_SELECT = 5;
    localparam INSTR_WIDTH = 32;
    localparam PC_WIDTH = 5;

    logic clk = 0, rst, nop;

    // Register select paths
    logic [PC_WIDTH -1 : 0] pc_0, pc_1;
    logic [REG_SELECT -1 : 0] reg_a_select_0, reg_a_select_1;
    logic [REG_SELECT -1 : 0] reg_b_select_0, reg_b_select_1;
    logic [REG_SELECT -1 : 0] reg_c_select_0, reg_c_select_1, reg_c_select_2, reg_c_select_3;

    // Data paths
    logic [INSTR_WIDTH -1 : 0] instruction_0, instruction_1;
    logic [REG_WIDTH -1 : 0] reg_a_0, reg_a_1;
    logic [REG_WIDTH -1 : 0] reg_b_0, reg_b_1, reg_b_2;
    logic [REG_WIDTH -1 : 0] offset_0, offset_1;
    logic [REG_WIDTH -1 : 0] alu_data_0, alu_data_1, alu_data_2;
    logic [REG_WIDTH -1 : 0] mem_data_0, mem_data_1;

    // Control signals
    logic       is_write_0, is_write_1, is_write_2, is_write_3;
    logic       is_load_0, is_load_1, is_load_2, is_load_3;
    logic       is_store_0, is_store_1, is_store_2;
    logic       cmp_data_0;
    alu_op_e    alu_op_0, alu_op_1;

    pipe_0 #(
        .INSTR_WIDTH(INSTR_WIDTH),
        .PC_WIDTH(PC_WIDTH)
    ) dut_0 (
        .clk(clk),
        .rst(rst),
        .enable(!nop),
        .flush(cmp_data_0),
        .i_instruction(instruction_0),
        .i_pc(pc_0),
        .o_instruction(instruction_1),
        .o_pc(pc_1)
    );

    pipe_1 #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) dut_1 (
        .clk(clk),
        .rst(rst),
        .enable(!nop),

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

    pipe_2 #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) dut_2 (
        .clk(clk),
        .rst(rst),
        .enable(!nop),

        .i_reg_b(reg_b_1),
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

    pipe_3 #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) dut_3 (
        .clk(clk),
        .rst(rst),
        .enable(!nop),

        .i_mem_data(mem_data_1),
        .i_alu_data(alu_data_1),
        .i_reg_c_select(reg_c_select_2),
        .i_is_write(is_write_2),
        .i_is_load(is_load_2),

        .o_mem_data(mem_data_0),
        .o_alu_data(alu_data_2),
        .o_reg_c_select(reg_c_select_3),
        .o_is_write(is_write_3),
        .o_is_load(is_load_3)
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
        $time, rst, nop, cmp_data_0, 
        instruction_0, instruction_1, pc_0, pc_1
    );

endmodule