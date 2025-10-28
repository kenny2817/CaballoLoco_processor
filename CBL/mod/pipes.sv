import alu_pkg::*;

module pipe_D #(
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

module pipe_A #(
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

module pipe_M #(
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

module pipe_W #(
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
