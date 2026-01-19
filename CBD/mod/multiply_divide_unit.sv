
import mdu_pkg::*;

module mdu #(
    parameter REG_WIDTH = 32,
    parameter int STAGES = 5
)(
    input  logic                  clk,
    input  logic                  rst, 
  
    input  mdu_control_t          i_control,  // Control signal

    input  logic [REG_WIDTH-1:0]  i_op1,      // First operand 
    input  logic [REG_WIDTH-1:0]  i_op2,      // Second operand

    output logic [REG_WIDTH-1:0]  o_result,   // result
    output logic                  o_cooking   // signal that the unit is busy cooking
);

    logic [REG_WIDTH-1:0] result_out  [STAGES];
    logic                 cooking_out [STAGES];

    assign o_result  = result_out[STAGES-1];
    assign o_cooking = |cooking_out;

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
            OP_MUL:    result_out[0] = prod_ss[   REG_WIDTH -1 :         0]; // Low word of S*S
            OP_MULH:   result_out[0] = prod_ss[2* REG_WIDTH -1 : REG_WIDTH]; // High word of S*S
            OP_MULHSU: result_out[0] = prod_su[2* REG_WIDTH -1 : REG_WIDTH]; // High word of S*U
            OP_MULHU:  result_out[0] = prod_uu[2* REG_WIDTH -1 : REG_WIDTH]; // High word of U*U
            
            // Division
            OP_DIV:    result_out[0] = div_s_result;
            OP_DIVU:   result_out[0] = div_u_result;
            
            // Remainder
            OP_REM:    result_out[0] = rem_s_result;
            OP_REMU:   result_out[0] = rem_u_result;
            
            default:   result_out[0] = 'x; // Undefined operation
        endcase
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < STAGES; i++) begin
                cooking_out[i] <= 1'b0;
            end
        end else begin
            cooking_out[0] <= i_control.enable;
            for (int i = STAGES -1; i > 0; i--) begin
                result_out[i-1]  <= result_out[i];
                cooking_out[i-1] <= cooking_out[i];
            end
        end
    end

endmodule
