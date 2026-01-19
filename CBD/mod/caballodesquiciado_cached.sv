import pipes_pkg::*;

module cbd #(
) (
    input logic         clk,
    input logic         rst,
    input logic [0 : 0] rnd
);

// LOCAL PARAMETERS =====================================================
    localparam int NUM_REG = 32;
    localparam int REG_WIDTH = 32;
    localparam int TLB_LINES = 2;
    localparam int CACHE_SECTORS = 4;
    localparam int CACHE_LINES = 1;
    localparam int CACHE_BYTES = 16;
    localparam int STB_LINES = 4;
    localparam int VA_WIDTH = 32;
    localparam int PA_WIDTH = 20;
    localparam int ID_WIDTH = 2;
    localparam int MEM_STAGES = 5;

// CABLE MANAGEMENT =====================================================

    // pipeline control
    logic enable_pipe_F, enable_pipe_D, enable_pipe_A, enable_pipe_M, enable_pipe_W, enable_pipe_WC;
    logic flush_pipe_D, flush_pipe_A, flush_pipe_M, flush_pipe_W, flush_pipe_WC;

    // control cables
    cable_pipe_D_t          i_pipe_D, o_pipe_D;
    cable_pipe_A_t          i_pipe_A, o_pipe_A;
    cable_pipe_M_t          i_pipe_M, o_pipe_M;
    cable_pipe_W_t          i_pipe_W, o_pipe_W;
    cable_pipe_WC_t         i_pipe_WC, o_pipe_WC;

    // pc
    logic [REG_WIDTH -1 : 0] pc;
    logic cmp_branch, ide_jal;

    // decode
    logic [REG_WIDTH -1 : 0] registers [NUM_REG];
    logic [4 : 0] select_rs1, select_rs2;

    // memory signals
    logic                   mem_instruction_enable, mem_data_enable;
    logic [PA_WIDTH -1 : 0] mem_instruction_addr,   mem_data_addr;
    logic                   mem_instruction_ack,    mem_data_ack;
    logic [CACHE_BYTES*8 - 1 : 0]                   mem_data_store;
    logic                                           mem_data_write;
    logic [ID_WIDTH -1 : 0]                         arb_id;
    logic                                           mem_response_enable;
    logic [CACHE_BYTES*8 - 1 : 0]                   mem_response_data;
    logic [ID_WIDTH -1 : 0]                         mem_response_id;

    // alu
    logic [REG_WIDTH -1 : 0] alu_result;
    logic alu_flag_zero, alu_flag_less_than;

    // mdu
    logic [REG_WIDTH -1 : 0] mdu_result;

    // memory
    logic                   mem_enable, mem_write;
    logic [PA_WIDTH   -1 : 0]     mem_addr; // address of data
    logic [CACHE_BYTES*8 - 1 : 0] mem_data; // actual data
    logic [ID_WIDTH   -1 : 0]     mem_id;

// PROGRAM COUNTER ======================================================
    reg_mono #(
        .DATA_WIDTH(REG_WIDTH)
    ) PC (
        .clk(clk),
        .rst(rst),

        .i_write_enable(enable_pipe_F),
        .i_write_data(pc),
        .o_read_data(i_pipe_D.pc)
    );

    // PC MANAGER
    always_comb begin
        if (cmp_branch) begin
            pc = o_pipe_D.pc + i_pipe_A.imm;
        end else if (o_pipe_A.jalr) begin
            pc = alu_result;
        end else if (ide_jal) begin
            pc = i_pipe_D.pc + i_pipe_A.imm;
        end else begin
            pc = i_pipe_D.pc +1;
        end
    end

    // INSTRUCTION MEMORY
    ime #(
        .TLB_LINES(TLB_LINES),
        .CACHE_SECTORS(CACHE_SECTORS),
        .CACHE_LINES(CACHE_LINES),
        .CACHE_BYTES(CACHE_BYTES),
        .REG_WIDTH(REG_WIDTH),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) IME (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),

        .i_virtual_addr(i_pipe_D.pc),

        .o_data_loaded(i_pipe_D.instruction),
        .o_tlb_miss(tlb_miss_F),
        .o_cache_miss(cache_miss_F),

        // tlb write
        .i_write_enable(TODO),
        .i_physical_addr(TODO),

        // mem
        .o_mem_enable(mem_instruction_enable),
        .o_mem_addr(mem_instruction_addr),
        .o_mem_ack(mem_instruction_ack),

        .i_mem_enable(mem_response_enable),
        .i_mem_data(mem_response_data),
        .i_mem_id_request(arb_id),
        .i_mem_id_response(mem_response_id),
        .i_mem_in_use(mem_data_enable)
    );

// PIPE_D ===============================================================

    localparam cable_pipe_D_t flush_value_D = '{
        instruction : 32'h00000013, // NOP
        pc          : 32'h00000000
    };

    pipe #(
        .CABLE_T(cable_pipe_D_t),
        .FLUSH_VALUE(flush_value_D)
    ) PIPE_D (
        .clk(clk),
        .rst(rst),
        .enable(enable_pipe_D),
        .flush(flush_pipe_D),

        .i_pipe(i_pipe_D),

        .o_pipe(o_pipe_D)
    );

    // Instruction Decoder
    ide IDE (
        .i_instruction(o_pipe_D.instruction),

        .o_alu_control(i_pipe_A.alu_control),
        .o_mdu_control(i_pipe_A.mdu_control),
        .o_cmp_control(i_pipe_A.cmp_control),
        .o_mem_control(i_pipe_A.mem_control),
        .o_wb_control(i_pipe_A.wb_control),

        .o_rs1(select_rs1),
        .o_rs2(select_rs2),
        .o_imm(i_pipe_A.imm),

        .o_jal(ide_jal),
        .o_jalr(i_pipe_A.jalr),
        .o_use_flag(i_pipe_A.use_flag),

        .o_bad_instruction(bad_instruction)
    );

    // REGISTER FILE
    reg_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_REG)
    ) REGISTERS (
        .clk(clk),
        .rst(rst),

        .i_write_enable(o_pipe_W.wb_control.is_write_back),
        .i_write_select(o_pipe_W.wb_control.rd),
        .i_write_data(i_pipe_WC.mux_result),

        .o_read_data(registers)
    );

    // MUX
    assign i_pipe_A.rs1 = registers[select_rs1];
    assign i_pipe_A.rs2 = registers[select_rs2];
    assign i_pipe_A.pc  = o_pipe_D.pc;

// PIPE_A ===============================================================

    localparam cable_pipe_A_t flush_value_A = '0;

    pipe #(
        .CABLE_T(cable_pipe_A_t),
        .FLUSH_VALUE(flush_value_A)
    ) PIPE_A (
        .clk(clk),
        .rst(rst),
        .enable(enable_pipe_A),
        .flush(flush_pipe_A),

        .i_pipe(i_pipe_A),

        .o_pipe(o_pipe_A)
    );

    // BYPASS
    logic [REG_WIDTH -1 : 0] bypass_rs1, bypass_rs2;
    assign bypass_rs1 = (o_pipe_M.wb_control.is_write_back  && (o_pipe_M.wb_control.rd  == select_rs1)) ? o_pipe_M.execution_result :
                        (o_pipe_W.wb_control.is_write_back  && (o_pipe_W.wb_control.rd  == select_rs1)) ? o_pipe_W.execution_result :
                        (o_pipe_WC.wb_control.is_write_back && (o_pipe_WC.wb_control.rd == select_rs1)) ? o_pipe_WC.mux_result      :
                        o_pipe_A.rs1;
    assign bypass_rs2 = (o_pipe_M.wb_control.is_write_back  && (o_pipe_M.wb_control.rd  == select_rs2)) ? o_pipe_M.execution_result :
                        (o_pipe_W.wb_control.is_write_back  && (o_pipe_W.wb_control.rd  == select_rs2)) ? o_pipe_W.execution_result :
                        (o_pipe_WC.wb_control.is_write_back && (o_pipe_WC.wb_control.rd == select_rs2)) ? o_pipe_WC.mux_result      :
                        o_pipe_A.rs2;

    // Arithmetic Logic Unit
    alu ALU (
        .i_control(o_pipe_A.alu_control),
        .i_rs1(bypass_rs1), // bypass
        .i_rs2(bypass_rs2), // bypass
        .i_imm(o_pipe_A.imm),
        .i_pc(o_pipe_A.pc),

        .o_result(alu_result),
        .o_zero(alu_flag_zero),
        .o_less_than(alu_flag_less_than)
    );

    // Multiply Divide Unit
    mdu MDU (
        .clk(clk),
        .rst(rst),

        .i_control(o_pipe_A.mdu_control),
        .i_op1(o_pipe_A.rs1),
        .i_op2(o_pipe_A.rs2),

        .o_result(mdu_result),
        .o_cooking(mdu_cooking)
    );

    // Comparator
    cmp CMP (
        .i_control(o_pipe_A.cmp_control),
        .i_alu_flag_zero(alu_flag_zero),
        .i_alu_flag_less_than(alu_flag_less_than),

        .o_branch(cmp_branch)
    );

    // MUX
    // selects between ALU result and compare result depending on use_flag and jalr pc +4
    assign i_pipe_M.execution_result =  o_pipe_A.mdu_control.enable ? 
                                        (o_pipe_A.jalr      ? o_pipe_A.pc +1                        : mdu_result) : 
                                        (o_pipe_A.use_flag  ? {31'h00000000, alu_flag_less_than}    : alu_result);

    assign i_pipe_M.rs2 = bypass_rs2; // pass rs2 for store operations
    assign i_pipe_M.mem_control = o_pipe_A.mem_control;
    assign i_pipe_M.wb_control  = o_pipe_A.wb_control;

// PIPE_M ==============================================================
    localparam cable_pipe_M_t flush_value_M = '0;

    pipe #(
        .CABLE_T(cable_pipe_M_t),
        .FLUSH_VALUE(flush_value_M)
    ) PIPE_M (
        .clk(clk),
        .rst(rst),
        .enable(enable_pipe_M),
        .flush(flush_pipe_M),

        .i_pipe(i_pipe_M),

        .o_pipe(o_pipe_M)
    );


    // Data Memory Engine - Data Cache - TLB interface
    dme #(
        .TLB_LINES(TLB_LINES),
        .CACHE_SECTORS(CACHE_SECTORS),
        .CACHE_LINES(CACHE_LINES),
        .CACHE_BYTES(CACHE_BYTES),
        .STB_LINES(STB_LINES),
        .REG_WIDTH(REG_WIDTH),
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) DME (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),

        .i_control(o_pipe_M.mem_control),
        .i_virtual_addr(o_pipe_M.execution_result),
        .i_write_data(o_pipe_A.rs2),

        .o_data_loaded(i_pipe_W.mem_data),
        .o_tlb_miss(tlb_miss_M),
        .o_cache_miss(cache_miss_M),
        .o_stb_full(stb_full_M),

        // tlb write
        .i_write_enable(TODO),
        .i_physical_addr(TODO),

        // mem
        .o_mem_enable(mem_data_enable),
        .o_mem_addr(mem_data_addr),
        .o_mem_data(mem_data_store),
        .o_mem_write(mem_data_write),
        .o_mem_ack(mem_data_ack),

        .i_mem_enable(mem_response_enable),
        .i_mem_data(mem_response_data),
        .i_mem_id_request(arb_id),
        .i_mem_id_response(mem_response_id)
    );

    assign i_pipe_W.execution_result    = o_pipe_M.execution_result;
    assign i_pipe_W.is_load             = o_pipe_M.mem_control.is_load;
    assign i_pipe_W.wb_control          = o_pipe_M.wb_control;

// PIPE_W ===============================================================

    localparam cable_pipe_W_t flush_value_W = '0;

    pipe #(
        .CABLE_T(cable_pipe_W_t),
        .FLUSH_VALUE(flush_value_W)
    ) PIPE_W (
        .clk(clk),
        .rst(rst),
        .enable(enable_pipe_W),
        .flush(flush_pipe_W),

        .i_pipe(i_pipe_W),

        .o_pipe(o_pipe_W)
    );

    // MUX
    assign i_pipe_WC.mux_result = o_pipe_W.is_load ? o_pipe_W.mem_data : o_pipe_W.execution_result;
    
    assign i_pipe_WC.wb_control = o_pipe_W.wb_control;

// PIPE_WC ==============================================================

    localparam cable_pipe_WC_t flush_value_WC = '0;
    
    pipe #(
        .CABLE_T(cable_pipe_WC_t),
        .FLUSH_VALUE(flush_value_WC)
    ) PIPE_WC (
        .clk(clk),
        .rst(rst),
        .enable(enable_pipe_WC),
        .flush(flush_pipe_WC),

        .i_pipe(i_pipe_WC),

        .o_pipe(o_pipe_WC)
    );

// HAZARD UNIT ==========================================================
    
    logic tlb_miss_F, cache_miss_F;
    logic tlb_miss_M, cache_miss_M, stb_full_M;
    logic mem_full;
    logic bad_instruction;
    logic mdu_cooking;

    // STALL
    logic stall_pipeline, stall_load_bypass;

    // full stall -> memory is overloaded | memory miss (tlb or cache) in M | store buffer full in M | mdu is cooking
    assign stall_pipeline = mem_full || tlb_miss_M || cache_miss_M || stb_full_M || mdu_cooking;
    // FD stall -> load-use hazard
    assign stall_load_bypass = o_pipe_A.mem_control.is_load && ((o_pipe_A.wb_control.rd == select_rs1) || (o_pipe_A.wb_control.rd == select_rs2));

    assign enable_pipe_F  = !(stall_pipeline || stall_load_bypass);
    assign enable_pipe_D  = !(stall_pipeline || stall_load_bypass);
    assign enable_pipe_A  = !(stall_pipeline);
    assign enable_pipe_M  = !(stall_pipeline);
    assign enable_pipe_W  = !(stall_pipeline);
    assign enable_pipe_WC = !(stall_pipeline);

    // FLUSH
    logic branch_misprediction;
    assign branch_misprediction = (cmp_branch); // for now no branch prediction implemented

    // flush on branch misprediction | jalr | tlb miss or cache miss in F | bad instruction in D
    assign flush_pipe_D   = (branch_misprediction || i_pipe_A.jalr || tlb_miss_F || cache_miss_F);
    assign flush_pipe_A   = (branch_misprediction || stall_load_bypass || bad_instruction);
    assign flush_pipe_M   = (0); // no flush in M
    assign flush_pipe_W   = (0); // no flush in W
    assign flush_pipe_WC  = (0); // no flush in WC

// MEMORY ===============================================================

    arb #(
        .PA_WIDTH(PA_WIDTH),
        .LINE_BYTES(CACHE_BYTES),
        .ID_WIDTH(ID_WIDTH)
    ) ARB (
        .clk(clk),
        .rst(rst),

        .i_instr_enable(mem_instruction_enable),
        .i_instr_addr(mem_instruction_addr),

        .i_data_enable(mem_data_enable),
        .i_data_addr(mem_data_addr),
        .i_data(mem_data_store),
        .i_data_write(mem_data_write),

        .o_mem_addr(mem_addr),
        .o_mem_data(mem_data),
        .o_mem_enable(mem_enable),
        .o_mem_write(mem_write),
        .o_mem_id(arb_id)
    );

    memory #(
        .PA_WIDTH(PA_WIDTH),
        .LINE_BYTES(CACHE_BYTES),
        .ID_WIDTH(ID_WIDTH),
        .STAGES(MEM_STAGES)
    ) MEM (
        .clk(clk),
        .rst(rst),

        .i_mem_enable(mem_enable),
        .i_mem_write(mem_write),
        .i_mem_addr(mem_addr),
        .i_mem_data(mem_data),
        .i_mem_id(arb_id),
        .i_mem_ack(mem_data_ack || mem_instruction_ack),

        .o_mem_enable(mem_response_enable),
        .o_mem_data(mem_response_data),
        .o_mem_id_response(mem_response_id),
        .o_mem_full(mem_full)        
    );

endmodule
