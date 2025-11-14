
import alu_pkg::*;

module alu #(
    parameter REG_WIDTH = 32
)(
    // control
    input  alu_control_t i_control,

    // input
    input  logic [REG_WIDTH -1 : 0] i_rs1,
    input  logic [REG_WIDTH -1 : 0] i_rs2,
    input  logic [REG_WIDTH -1 : 0] i_imm,
    input  logic [REG_WIDTH -1 : 0] i_pc,

    // output
    output logic [REG_WIDTH -1 : 0] o_result,

    // flags
    output logic                    o_zero,       
    output logic                    o_less_than
);

    logic [REG_WIDTH-1:0] alu_op1;
    logic [REG_WIDTH-1:0] alu_op2;

    // op1
    always_comb begin
        case (control.op1_sel)
            OP_REG:  alu_op1 = reg_rs1;
            OP_IMM:  alu_op1 = imm;
            OP_PC:   alu_op1 = pc;
            OP_ZERO: alu_op1 = '0;
            default: alu_op1 = '0;
        endcase
    end

    // op2
    always_comb begin
        case (control.op2_sel)
            OP_REG:  alu_op2 = reg_rs2;
            OP_IMM:  alu_op2 = imm;
            // OP_PC:   alu_op2 = pc;
            OP_ZERO: alu_op2 = '0;
            default: alu_op2 = '0;
        endcase
    end

    always_comb begin
        // add-sub
        // A-B is implemented as A + (~B) + 1
        logic op_is_sub = (control.operation == OP_SUB);
        logic [REG_WIDTH-1:0] op2verted = op_is_sub ? ~alu_op2 : alu_op2;
        // REG_WIDTH +1 bit adder to capture the carry-out
        logic [REG_WIDTH:0] adder_result_ext = alu_op1 + op2verted + op_is_sub;
        logic [REG_WIDTH-1:0] adder_result = adder_result_ext[REG_WIDTH-1:0];

        // logic
        logic [REG_WIDTH-1:0] and_result = alu_op1 & alu_op2;
        logic [REG_WIDTH-1:0] or_result  = alu_op1 | alu_op2;
        logic [REG_WIDTH-1:0] xor_result = alu_op1 ^ alu_op2;
        // shift
        logic [4 : 0] shamt = alu_op2[4 : 0];
        logic [REG_WIDTH-1:0] sll_result = alu_op1 << shamt;
        logic [REG_WIDTH-1:0] srl_result = alu_op1 >> shamt;
        logic [REG_WIDTH-1:0] sra_result = $signed(alu_op1) >>> shamt; 

        // result
        case (control.operation)
            OP_ADD:  result = adder_result;
            OP_SUB:  result = adder_result;
            OP_AND:  result = and_result;
            OP_OR:   result = or_result;
            OP_XOR:  result = xor_result;
            OP_SLL:  result = sll_result;
            OP_SRL:  result = srl_result;
            OP_SRA:  result = sra_result;
            default: result = '0;
        endcase

        // flags
        // They are only meaningful when the operation was OP_ADD or OP_SUB.

        // zero: result is all zeros
        o_zero = (adder_result == '0);

        // N (Sign): MSB of the result
        logic N = adder_result[REG_WIDTH -1];

        // C (Carry): Carry-out of the adder. 
        // For SUB (A + ~B + 1), C=1 means A >= B (no borrow)
        logic C = adder_result_ext[REG_WIDTH];

        // V (Overflow): Signed overflow
        logic op1_sign = alu_op1[REG_WIDTH-1];
        logic op2_sign = alu_op2[REG_WIDTH-1];
        logic add_overflow = (op1_sign == op2_sign) && (op1_sign != N);
        logic sub_overflow = (op1_sign != op2_sign) && (op1_sign != N);
        logic V = op_is_sub ? sub_overflow : add_overflow;

        logic signed_less_than   = N ^ V; // True if (N=1, V=0) or (N=0, V=1)
        logic unsigned_less_than = ~C;    // True if C=0 (borrow occurred)
        o_less_than = control.use_unsigned ? unsigned_less_than : signed_less_than;
    end

endmodule
