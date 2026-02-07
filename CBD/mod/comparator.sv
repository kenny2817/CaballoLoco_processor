
module cmp 
    import enums_pkg::*;
    import cable_pkg::*;
(
    input cmp_control_t i_control,
    input logic         i_alu_flag_zero,
    input logic         i_alu_flag_less_than,

    output logic        o_branch
);
    always_comb begin
        o_branch = 1'b0;
        if (i_control.enable) begin
            case (i_control.operation)
                OP_BEQ:     o_branch = i_alu_flag_zero;
                OP_BNE:     o_branch = !i_alu_flag_zero;
                OP_BLT:     o_branch = i_alu_flag_less_than;
                OP_BGE:     o_branch = !i_alu_flag_less_than || i_alu_flag_zero;
                default:    o_branch = 1'b0;
            endcase
        end
    end
endmodule
