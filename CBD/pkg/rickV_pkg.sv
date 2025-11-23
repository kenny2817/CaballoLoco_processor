
package riscv_instr_pkg;
    typedef enum logic [6:0] {
        // === Base Integer (I) ===
        // ALU R-type
        INSTR_ADD,
        INSTR_SUB,
        INSTR_XOR,
        INSTR_OR,
        INSTR_AND,
        INSTR_SLL,
        INSTR_SRL,
        INSTR_SRA,
        INSTR_SLT,
        INSTR_SLTU,
        
        // ALU I-type (immediate)
        INSTR_ADDI,
        INSTR_XORI,
        INSTR_ORI,
        INSTR_ANDI,
        INSTR_SLLI,
        INSTR_SRLI,
        INSTR_SRAI,
        INSTR_SLTI,
        INSTR_SLTIU,
        
        // Branch
        INSTR_BEQ,
        INSTR_BNE,
        INSTR_BLT,
        INSTR_BGE,
        INSTR_BLTU,
        INSTR_BGEU,
        
        // Load
        INSTR_LB,
        INSTR_LH,
        INSTR_LW,
        INSTR_LBU,
        INSTR_LHU,
        
        // Store
        INSTR_SB,
        INSTR_SH,
        INSTR_SW,
        
        // Jump
        INSTR_JAL,
        INSTR_JALR,
        
        // Upper immediate
        INSTR_LUI,
        INSTR_AUIPC,
        
        // System
        INSTR_ECALL,
        INSTR_EBREAK,
        
        // === M Extension (Multiply/Divide) ===
        INSTR_MUL,
        INSTR_MULH,
        INSTR_MULHSU,
        INSTR_MULHU,
        INSTR_DIV,
        INSTR_DIVU,
        INSTR_REM,
        INSTR_REMU,
        
        // Invalid/Unknown
        INSTR_INVALID
    } riscv_instr_e;
    
    // Instruction format types
    typedef enum logic [2:0] {
        FMT_R,      // Register-register
        FMT_I,      // Immediate
        FMT_S,      // Store
        FMT_B,      // Branch
        FMT_U,      // Upper immediate
        FMT_J,      // Jump
        FMT_UNKNOWN
    } instr_format_e;
    
    // Decoded instruction structure
    typedef struct packed {
        riscv_instr_e instr_type;
        instr_format_e format;
        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [4:0] rd;
        logic [31:0] imm;
        logic valid;
    } decoded_instr_t;
    
    // Decoder function with extension support
    function automatic decoded_instr_t decode_instruction(
        logic [31:0] instr
    );
        decoded_instr_t result;
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic [4:0] funct5;
        
        opcode = instr[6:0];
        funct3 = instr[14:12];
        funct7 = instr[31:25];
        funct5 = instr[31:27];
        
        // Extract register fields
        result.rs1 = instr[19:15];
        result.rs2 = instr[24:20];
        result.rd  = instr[11:7];
        result.valid = 1'b1;
        
        // Decode based on opcode
        case (opcode)
            7'b0110011: begin // R-type ALU and extensions
                result.format = FMT_R;
                result.imm = 32'h0;
                
                // Check for M extension (funct7 = 0000001)
                if (funct7 == 7'b0000001) begin
                    case (funct3)
                        3'b000: result.instr_type = INSTR_MUL;
                        3'b001: result.instr_type = INSTR_MULH;
                        3'b010: result.instr_type = INSTR_MULHSU;
                        3'b011: result.instr_type = INSTR_MULHU;
                        3'b100: result.instr_type = INSTR_DIV;
                        3'b101: result.instr_type = INSTR_DIVU;
                        3'b110: result.instr_type = INSTR_REM;
                        3'b111: result.instr_type = INSTR_REMU;
                    endcase
                end else begin
                    // Base integer instructions
                    case (funct3)
                        3'b000: result.instr_type = (funct7[5]) ? INSTR_SUB : INSTR_ADD;
                        3'b001: result.instr_type = INSTR_SLL;
                        3'b010: result.instr_type = INSTR_SLT;
                        3'b011: result.instr_type = INSTR_SLTU;
                        3'b100: result.instr_type = INSTR_XOR;
                        3'b101: result.instr_type = (funct7[5]) ? INSTR_SRA : INSTR_SRL;
                        3'b110: result.instr_type = INSTR_OR;
                        3'b111: result.instr_type = INSTR_AND;
                    endcase
                end
            end
            
            7'b0010011: begin // I-type ALU
                result.format = FMT_I;
                result.imm = {{20{instr[31]}}, instr[31:20]};
                case (funct3)
                    3'b000: result.instr_type = INSTR_ADDI;
                    3'b001: result.instr_type = INSTR_SLLI;
                    3'b010: result.instr_type = INSTR_SLTI;
                    3'b011: result.instr_type = INSTR_SLTIU;
                    3'b100: result.instr_type = INSTR_XORI;
                    3'b101: result.instr_type = (funct7[5]) ? INSTR_SRAI : INSTR_SRLI;
                    3'b110: result.instr_type = INSTR_ORI;
                    3'b111: result.instr_type = INSTR_ANDI;
                endcase
            end
            
            7'b1100011: begin // Branch
                result.format = FMT_B;
                result.imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
                case (funct3)
                    3'b000: result.instr_type = INSTR_BEQ;
                    3'b001: result.instr_type = INSTR_BNE;
                    3'b100: result.instr_type = INSTR_BLT;
                    3'b101: result.instr_type = INSTR_BGE;
                    3'b110: result.instr_type = INSTR_BLTU;
                    3'b111: result.instr_type = INSTR_BGEU;
                    default: begin
                        result.instr_type = INSTR_INVALID;
                        result.valid = 1'b0;
                    end
                endcase
            end
            
            7'b0000011: begin // Load
                result.format = FMT_I;
                result.imm = {{20{instr[31]}}, instr[31:20]};
                case (funct3)
                    3'b000: result.instr_type = INSTR_LB;
                    3'b001: result.instr_type = INSTR_LH;
                    3'b010: result.instr_type = INSTR_LW;
                    3'b100: result.instr_type = INSTR_LBU;
                    3'b101: result.instr_type = INSTR_LHU;
                    default: begin
                        result.instr_type = INSTR_INVALID;
                        result.valid = 1'b0;
                    end
                endcase
            end
            
            7'b0100011: begin // Store
                result.format = FMT_S;
                result.imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                case (funct3)
                    3'b000: result.instr_type = INSTR_SB;
                    3'b001: result.instr_type = INSTR_SH;
                    3'b010: result.instr_type = INSTR_SW;
                    default: begin
                        result.instr_type = INSTR_INVALID;
                        result.valid = 1'b0;
                    end
                endcase
            end
            
            7'b1101111: begin // JAL
                result.format = FMT_J;
                result.imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
                result.instr_type = INSTR_JAL;
            end
            
            7'b1100111: begin // JALR
                result.format = FMT_I;
                result.imm = {{20{instr[31]}}, instr[31:20]};
                result.instr_type = INSTR_JALR;
            end
            
            7'b0110111: begin // LUI
                result.format = FMT_U;
                result.imm = {instr[31:12], 12'h0};
                result.instr_type = INSTR_LUI;
            end
            
            7'b0010111: begin // AUIPC
                result.format = FMT_U;
                result.imm = {instr[31:12], 12'h0};
                result.instr_type = INSTR_AUIPC;
            end
            
            7'b1110011: begin // System
                result.format = FMT_I;
                result.imm = 32'h0;
                if (instr[31:20] == 12'h000)
                    result.instr_type = INSTR_ECALL;
                else if (instr[31:20] == 12'h001)
                    result.instr_type = INSTR_EBREAK;
                else begin
                    result.instr_type = INSTR_INVALID;
                    result.valid = 1'b0;
                end
            end
            
            default: begin
                result.format = FMT_UNKNOWN;
                result.instr_type = INSTR_INVALID;
                result.imm = 32'h0;
                result.valid = 1'b0;
            end
        endcase
        
        return result;
    endfunction

endpackage