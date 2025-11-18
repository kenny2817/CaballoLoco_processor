
import mul_pkg::*;

module mul_div_unit #(
    parameter REG_WIDTH
)(
    input  mdu_control_t          i_control,  // Control signal

    input  logic [REG_WIDTH-1:0]  i_op1,      // First operand 
    input  logic [REG_WIDTH-1:0]  i_op2,      // Second operand

    output logic [REG_WIDTH-1:0]  o_result    // result
);

    always_comb begin
        // MUL    
        // signed x signed
        logic [2*REG_WIDTH-1:0] prod_ss = $signed(i_op1) * $signed(i_op2);
        
        // unsigned x unsigned
        logic [2*REG_WIDTH-1:0] prod_uu = i_op1 * i_op2;

        // signed x unsigned
        logic [2*REG_WIDTH-1:0] prod_su = $signed(i_op1) * i_op2;

        // DIV REM
        // Signed
        logic [REG_WIDTH-1:0] div_s_result = $signed(i_op1) / $signed(i_op2);
        logic [REG_WIDTH-1:0] rem_s_result = $signed(i_op1) % $signed(i_op2);
        
        // Unsigned
        logic [REG_WIDTH-1:0] div_u_result = i_op1 / i_op2;
        logic [REG_WIDTH-1:0] rem_u_result = i_op1 % i_op2;

        case (i_control.operation)
            // Multiplication
            OP_MUL:    result_out = prod_ss[   REG_WIDTH -1 :         0]; // Low word of S*S
            OP_MULH:   result_out = prod_ss[2* REG_WIDTH -1 : REG_WIDTH]; // High word of S*S
            OP_MULHSU: result_out = prod_su[2* REG_WIDTH -1 : REG_WIDTH]; // High word of S*U
            OP_MULHU:  result_out = prod_uu[2* REG_WIDTH -1 : REG_WIDTH]; // High word of U*U
            
            // Division
            OP_DIV:    result_out = div_s_result;
            OP_DIVU:   result_out = div_u_result;
            
            // Remainder
            OP_REM:    result_out = rem_s_result;
            OP_REMU:   result_out = rem_u_result;
            
            default:   result_out = 'x; // Undefined operation
        endcase
    end

endmodule