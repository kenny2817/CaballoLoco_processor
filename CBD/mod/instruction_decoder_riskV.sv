import riscv_instr_pkg::*;
import alu_pkg::*;
import mdu_pkg::*;
import cable_pkg::*;


module ide (
    input logic [31 : 0]    i_instruction,

    // Outputs
    output alu_control_t    o_alu_control,
    output mdu_control_t    o_mdu_control,
    output cmp_control_t    o_cmp_control,
    output mem_control_t    o_mem_control,
    output wb_control_t     o_wb_control,

    output logic [4 : 0]    o_rs1,
    output logic [4 : 0]    o_rs2,
    output logic [31 : 0]   o_imm,

    output logic            o_jal,
    output logic            o_jalr,
    output logic            o_use_flag,

    output logic           o_bad_instruction
);

    decoded_instr_t decoded;

    // tasks
        task automatic set_alu(
            risk_alu_e                  operation,
            risk_alu_operand_selector_e op1_sel,
            risk_alu_operand_selector_e op2_sel,
            logic                       use_unsigned
        );
            o_alu_control.operation     = operation;
            o_alu_control.op1_sel       = op1_sel;
            o_alu_control.op2_sel       = op2_sel;
            o_alu_control.use_unsigned  = use_unsigned;
        endtask

        task automatic set_mdu(
            logic                       enable,
            risk_mdu_e                  operation
        );
            o_mdu_control.enable        = enable;
            o_mdu_control.operation     = operation;
        endtask

        task automatic set_mem(
            logic                       is_load,
            logic                       is_store,
            risk_mem_e                  size,
            logic                       use_unsigned
        );
            o_mem_control.is_load       = is_load;
            o_mem_control.is_store      = is_store;
            o_mem_control.size          = size;
            o_mem_control.use_unsigned  = use_unsigned;
            set_alu(OP_ADD, OP_REG, OP_IMM, 1'b0);
        endtask

        task automatic set_cmp(
            logic                       enable,
            risk_cmp_e                  operation,
            logic                       use_unsigned
        );
            o_cmp_control.enable        = enable;
            o_cmp_control.operation     = operation;
            set_alu(OP_SUB, OP_REG, OP_REG, use_unsigned);
        endtask

    always_comb begin

        decoded = decode_instruction(i_instruction);

        o_rs1 = decoded.rs1;
        o_rs2 = decoded.rs2;
        o_imm = decoded.imm;

        set_alu(OP_ADD, OP_REG, OP_REG, 1'b0);
        set_mdu(1'b0, OP_MUL);
        set_mem(1'b0, 1'b0, SIZE_WORD, 1'b0);
        set_cmp(1'b0, OP_BEQ, 1'b0);

        o_wb_control.is_write_back  = 1'b0;
        o_wb_control.rd             = decoded.rd;
        o_jal                       = 1'b0;
        o_use_flag                  = 1'b0;

        o_bad_instruction          = ~decoded.valid;

        if (decoded.valid) begin            
            case (decoded.format)
                FMT_R: begin
                    o_wb_control.is_write_back  = 1'b1;
                    case (decoded.instr_type)
                        INSTR_ADD:      set_alu(OP_ADD, OP_REG, OP_REG, 'x  );
                        INSTR_SUB:      set_alu(OP_SUB, OP_REG, OP_REG, 'x  );
                        INSTR_XOR:      set_alu(OP_XOR, OP_REG, OP_REG, 'x  );
                        INSTR_OR:       set_alu(OP_OR,  OP_REG, OP_REG, 'x  );
                        INSTR_AND:      set_alu(OP_AND, OP_REG, OP_REG, 'x  );
                        INSTR_SLL:      set_alu(OP_SLL, OP_REG, OP_REG, 'x  );
                        INSTR_SRL:      set_alu(OP_SRL, OP_REG, OP_REG, 'x  );
                        INSTR_SRA:      set_alu(OP_SRA, OP_REG, OP_REG, 'x  );
                        INSTR_SLT:      set_alu(OP_SUB, OP_REG, OP_REG, 1'b0);
                        INSTR_SLTU:     set_alu(OP_SUB, OP_REG, OP_REG, 1'b1);

                        INSTR_MUL:      set_mdu(1'b1, OP_MUL   );
                        INSTR_MULH:     set_mdu(1'b1, OP_MULH  );
                        INSTR_MULHSU:   set_mdu(1'b1, OP_MULHSU);
                        INSTR_MULHU:    set_mdu(1'b1, OP_MULHU );
                        INSTR_DIV:      set_mdu(1'b1, OP_DIV   );
                        INSTR_DIVU:     set_mdu(1'b1, OP_DIVU  );
                        INSTR_REM:      set_mdu(1'b1, OP_REM   );
                        INSTR_REMU:     set_mdu(1'b1, OP_REMU  );

                        default: ; // do nothing
                    endcase
                end 
                FMT_I: begin
                    o_wb_control.is_write_back  = 1'b1;
                    case (decoded.instr_type)
                        INSTR_ADDI:     set_alu(OP_ADD, OP_REG, OP_IMM, 'x  );
                        INSTR_XORI:     set_alu(OP_SUB, OP_REG, OP_IMM, 'x  );
                        INSTR_ORI:      set_alu(OP_OR,  OP_REG, OP_IMM, 'x  );
                        INSTR_ANDI:     set_alu(OP_AND, OP_REG, OP_IMM, 'x  );
                        INSTR_SLLI:     set_alu(OP_SLL, OP_REG, OP_IMM, 'x  );
                        INSTR_SRLI:     set_alu(OP_SRL, OP_REG, OP_IMM, 'x  );
                        INSTR_SRAI:     set_alu(OP_SRA, OP_REG, OP_IMM, 'x  );
                        INSTR_SLTI:     set_alu(OP_SUB, OP_REG, OP_IMM, 1'b0);
                        INSTR_SLTIU:    set_alu(OP_SUB, OP_REG, OP_IMM, 1'b1);

                        INSTR_LB:       set_mem(1'b1, 1'b0, SIZE_BYTE, 1'b0);
                        INSTR_LH:       set_mem(1'b1, 1'b0, SIZE_HALF, 1'b0);
                        INSTR_LW:       set_mem(1'b1, 1'b0, SIZE_WORD, 1'b0);
                        INSTR_LBU:      set_mem(1'b1, 1'b0, SIZE_BYTE, 1'b1);
                        INSTR_LHU:      set_mem(1'b1, 1'b0, SIZE_HALF, 1'b1);

                        INSTR_JALR: begin 
                            o_jalr = 1'b1;
                            set_alu(OP_ADD, OP_REG, OP_IMM, 'x  );
                        end

                        // INSTR_ECALL: 
                        // INSTR_EBREAK: // no idea of how to manage them

                        default: ; // do nothing
                    endcase
                end
                FMT_S: begin
                    case (decoded.instr_type)
                        INSTR_SB:       set_mem(1'b0, 1'b1, SIZE_BYTE, 1'b0);
                        INSTR_SH:       set_mem(1'b0, 1'b1, SIZE_HALF, 1'b0);
                        INSTR_SW:       set_mem(1'b0, 1'b1, SIZE_WORD, 1'b0);

                        default: ; // do nothing
                    endcase
                end
                FMT_B: begin
                    case (decoded.instr_type)
                        INSTR_BEQ:      set_cmp(1'b1, OP_BEQ, 1'b0);
                        INSTR_BNE:      set_cmp(1'b1, OP_BNE, 1'b0);
                        INSTR_BLT:      set_cmp(1'b1, OP_BLT, 1'b0);
                        INSTR_BGE:      set_cmp(1'b1, OP_BGE, 1'b0);
                        INSTR_BLTU:     set_cmp(1'b1, OP_BLT, 1'b1);
                        INSTR_BGEU:     set_cmp(1'b1, OP_BGE, 1'b1);

                        default: ; // do nothing
                    endcase
                end
                FMT_U: begin
                    o_wb_control.is_write_back  = 1'b1;
                    o_use_flag = 1'b1;
                    case (decoded.instr_type)
                        INSTR_LUI:      set_alu(OP_ADD, OP_REG, OP_IMM, 'x  );
                        INSTR_AUIPC:    set_alu(OP_ADD, OP_REG, OP_IMM, 'x  );

                        default: ; // do nothing
                    endcase
                end
                FMT_J: begin
                    case (decoded.instr_type)
                        INSTR_JAL: o_jal = 1'b1;

                        default: ; // do nothing
                    endcase
                end
                FMT_UNKNOWN: begin
                    // do nothing, all outputs are already in default values
                end
                default: begin
                    // do nothing, all outputs are already in default values
                end
            endcase
        end
    end

endmodule
