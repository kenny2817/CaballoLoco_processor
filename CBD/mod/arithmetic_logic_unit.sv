
import alu_pkg::*;

module alu #(
    parameter REG_WIDTH = 32
)(
    // control
    input  alu_control_t            i_control,

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

    // operands
    logic [REG_WIDTH-1:0] alu_op1;
    logic [REG_WIDTH-1:0] alu_op2;

    // internal logic
    logic [REG_WIDTH    : 0] adder_result_ext; // dim is REG_WIDTH + 1 to contain the carry-out (extra bit)
    logic [REG_WIDTH -1 : 0] adder_result;
    logic [REG_WIDTH -1 : 0] op2verted;
    logic [REG_WIDTH -1 : 0] and_result;
    logic [REG_WIDTH -1 : 0] or_result;
    logic [REG_WIDTH -1 : 0] xor_result;
    logic [REG_WIDTH -1 : 0] sll_result;
    logic [REG_WIDTH -1 : 0] srl_result;
    logic [REG_WIDTH -1 : 0] sra_result;

    // localparam int SHAMT_WIDTH = $clog2(REG_WIDTH);
    // logic [SHAMT_WIDTH-1: 0] shamt;
    logic [4            : 0] shamt; //TODO: to be parametrized for sizes other than 32
    logic                    op_is_sub;

    // flags
    logic N, C, V;
    logic op1_sign, op2_sign;
    logic add_overflow, sub_overflow;
    logic signed_less_than, unsigned_less_than;

    // op1
    always_comb begin
        case (i_control.op1_sel)
            OP_REG:  alu_op1 = i_rs1;
            OP_IMM:  alu_op1 = i_imm;
            OP_PC:   alu_op1 = i_pc;
            OP_ZERO: alu_op1 = '0;
            default: alu_op1 = '0;
        endcase
    end

    // op2
    always_comb begin
        case (i_control.op2_sel)
            OP_REG:  alu_op2 = i_rs2;
            OP_IMM:  alu_op2 = i_imm;
            // OP_PC:   alu_op2 = i_pc;
            OP_ZERO: alu_op2 = '0;
            default: alu_op2 = '0;
        endcase
    end

    always_comb begin
        // add-sub
        // A-B is implemented as A + (~B) + 1
        op_is_sub = (i_control.operation == OP_SUB);
        op2verted = op_is_sub ? ~alu_op2 : alu_op2;
        // REG_WIDTH +1 bit adder to capture the carry-out
        adder_result_ext = alu_op1 + op2verted + 33'(op_is_sub);
        adder_result = adder_result_ext[REG_WIDTH-1:0];

        // logic
        and_result = alu_op1 & alu_op2;
        or_result  = alu_op1 | alu_op2;
        xor_result = alu_op1 ^ alu_op2;
        // shift
        // shamt = alu_op2[SHAMT_WIDTH-1:0];
        shamt = alu_op2[4 : 0]; //TODO: to be parametrized for sizes other than 32
        sll_result = alu_op1 << shamt;
        srl_result = alu_op1 >> shamt;
        sra_result = $signed(alu_op1) >>> shamt; 

        // result
        case (i_control.operation)
            OP_ADD:  o_result = adder_result;
            OP_SUB:  o_result = adder_result;
            OP_AND:  o_result = and_result;
            OP_OR:   o_result = or_result;
            OP_XOR:  o_result = xor_result;
            OP_SLL:  o_result = sll_result;
            OP_SRL:  o_result = srl_result;
            OP_SRA:  o_result = sra_result;
            default: o_result = '0;
        endcase

        // flags
        // They are only meaningful when the operation was OP_ADD or OP_SUB.

        // zero: result is all zeros
        o_zero = (adder_result == '0);

        // N (Sign): MSB of the result
        N = adder_result[REG_WIDTH -1];

        // C (Carry): Carry-out of the adder. 
        // For SUB (A + ~B + 1), C=1 means A >= B (no borrow)
        C = adder_result_ext[REG_WIDTH];

        // V (Overflow): Signed overflow
        op1_sign = alu_op1[REG_WIDTH-1];
        op2_sign = alu_op2[REG_WIDTH-1];
        add_overflow = (op1_sign == op2_sign) && (op1_sign != N);
        sub_overflow = (op1_sign != op2_sign) && (op1_sign != N);
        V = op_is_sub ? sub_overflow : add_overflow;

        // alternativa più semplice per less-than signed usando compare diretto
        // signed_less_than = ($signed(alu_op1) < $signed(alu_op2));
        // unsigned_less_than = ($unsigned(alu_op1) < $unsigned(alu_op2));

        signed_less_than   = N ^ V; // True if (N=1, V=0) or (N=0, V=1)
        unsigned_less_than = ~C;    // True if C=0 (borrow occurred)
        o_less_than = i_control.use_unsigned ? unsigned_less_than : signed_less_than;
    end

endmodule
