module haz #(
    parameter REG_SELECT
) (
    input logic                     i_is_cmp_D,
    input logic                     i_is_write_A,
    input logic                     i_is_load_D,
    input logic                     i_is_load_A,
    input logic [REG_SELECT -1 : 0] i_reg_a_select_D,
    input logic [REG_SELECT -1 : 0] i_reg_b_select_D,
    input logic [REG_SELECT -1 : 0] i_reg_c_select_A,

    output logic o_nop
);

    wire STALL = 1'b1;
    wire CHILL = 1'b0;

    always_comb begin
        // ALU-write hazard
        if  (i_is_cmp_D && i_is_write_A && (
            (i_reg_a_select_D == i_reg_c_select_A) ||
            (i_reg_b_select_D == i_reg_c_select_A))) begin
            o_nop = STALL;
        // Load-use hazard
        end else if (i_is_load_A) begin
            if (i_is_load_D) begin
                if (i_reg_a_select_D == i_reg_c_select_A) begin
                    o_nop = STALL;
                end else begin
                    o_nop = CHILL;
                end
            end else begin
                if ((i_reg_a_select_D == i_reg_c_select_A) || 
                    (i_reg_b_select_D == i_reg_c_select_A)) begin
                    o_nop = STALL;
                end else begin
                    o_nop = CHILL;
                end
            end
        end else begin
            o_nop = CHILL;
        end
    end
    
endmodule
