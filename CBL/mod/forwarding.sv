module fwd #(
    parameter REG_WIDTH,
    parameter REG_SELECT
) (
    input logic [REG_SELECT -1 : 0] i_reg_a_select,
    input logic [REG_SELECT -1 : 0] i_reg_b_select,

    input logic                     i_is_write_M,
    input logic [REG_SELECT -1 : 0] i_reg_c_select_M,

    input logic                     i_is_write_W,
    input logic [REG_SELECT -1 : 0] i_reg_c_select_W,

    output logic                    o_forward_a,
    output logic                    o_select_forward_a, // 0: from MEM stage, 1: from WB stage

    output logic                    o_forward_b, 
    output logic                    o_select_forward_b // 0: from MEM stage, 1: from WB stage
);
    // FORWARD A
    always_comb begin
        if (i_is_write_M && (i_reg_a_select == i_reg_c_select_M)) begin // load is managed by hazard unit
            o_forward_a         = 1'b1;
            o_select_forward_a  = 1'b0;
        end else if (i_is_write_W && (i_reg_a_select == i_reg_c_select_W)) begin
            o_forward_a         = 1'b1;
            o_select_forward_a  = 1'b1;
        end else begin
            o_forward_a         = 1'b0;
            o_select_forward_a  = 'x;
        end
    end
    
    // FORWARD B
    always_comb begin
        if (i_is_write_M && (i_reg_b_select == i_reg_c_select_M)) begin // load is managed by hazard unit
            o_forward_b         = 1'b1;
            o_select_forward_b  = 1'b0;
        end else if (i_is_write_W && (i_reg_b_select == i_reg_c_select_W)) begin
            o_forward_b         = 1'b1;
            o_select_forward_b  = 1'b1;
        end else begin
            o_forward_b         = 1'b0;
            o_select_forward_b  = 'x;
        end
    end
    
endmodule
