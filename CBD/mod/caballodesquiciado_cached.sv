
module cbd #(
) (
    input logic clk,
    input logic rst
);

// LOCAL PARAMETERS =====================================================
    parameter int NUM_REG = 32;
    parameter int REG_WIDTH = 32;

// CABLE MANAGEMENT =====================================================

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
    logic [LINE_WIDTH -1 : 0]                       mem_data_store;
    logic                                           mem_data_write;
    logic [ID_WIDTH -1 : 0] arb_id;

    // alu
    logic [REG_WIDTH -1 : 0] alu_result;
    logic alu_flag_zero, alu_flag_less_than;

    // memory
    logic                   mem_enable, mem_write;
    logic [PA_WIDTH   -1 : 0]     mem_addr; // address of data
    logic [LINE_WIDTH -1 : 0]     mem_data; // actual data
    logic [ID_WIDTH   -1 : 0]     mem_id;

// PROGRAM COUNTER ======================================================
    reg_mono #(
        .DATA_WIDTH()
    ) PC (
        .clk(clk),
        .rst(rst),

        .i_write_enable(),
        .i_write_data(pc),
        .o_read_data(i_pipe_D.pc)
    );

    // PC MANAGER
    always_comb begin
        if (cmp_branch) begin
            pc = o_pipe_D.pc + i_pipe_A.alu_control.imm;
        end else if (o_pipe_A.jalr) begin
            pc = alu_result;
        end else if (ide_jal) begin
            pc = i_pipe_D.pc + i_pipe_A.alu_control.imm;
        end else begin
            pc = i_pipe_D.pc +1;
        end
    end

    // Instruction MEmory
    ime IME #(
        .TLB_LINES(),
        .CACHE_SECTORS(),
        .CACHE_LINES(),
        .CACHE_BYTES(),
        .VA_WIDTH(),
        .PA_WIDTH(),
        .ID_WIDTH()
    ) IME (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),

        .i_enable(),
        .i_virtual_addr(i_pipe_D.pc),

        .o_data_loaded(i_pipe_D.instruction),
        .o_exeption(),
        .o_stall(),

        // tlb write
        .i_write_enable(),
        .i_physical_addr(),

        // mem
        .o_mem_enable(mem_instruction_enable),
        .o_mem_addr(mem_instruction_addr),
        .o_mem_ack(mem_instruction_ack),

        .i_mem_enable(),
        .i_mem_data(),
        .i_mem_id_request(arb_id),
        .i_mem_id_response(),
        .i_mem_in_use(mem_data_enable)
    );

// PIPE_D ===============================================================
    pipe #(
        .CABLE_T(cable_pipe_D_t)
    ) PIPE_D (
        .clk(clk),
        .rst(rst),
        .enable(),

        .i_pipe(i_pipe_D),

        .o_pipe(o_pipe_D)
    );

    // Instruction Decoder
    ide IDE (
        .clk(clk),
        .rst(rst),

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
        .o_use_flag(i_pipe_A.use_flag)
    );

    // REGISTER FILE
    reg_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_REG)
    ) REGISTERS (
        .clk(clk),
        .rst(rst),

        .i_write_enable(o_pipe_W.wb_control.is_write_back),
        .i_write_select(o_pipe_W.wb_control.rdf),
        .i_write_data(),

        .o_read_data(registers)
    );

    // MUX
    assign i_pipe_A.rs1 = registers[select_rs1];
    assign i_pipe_A.rs2 = registers[select_rs2];

// PIPE_A ===============================================================
    pipe #(
        .CABLE_T(cable_pipe_A_t)
    ) PIPE_A (
        .clk(clk),
        .rst(rst),
        .enable(),

        .i_pipe(i_pipe_A),

        .o_pipe(o_pipe_A)
    );

    // BYPASS
    logic [REG_WIDTH -1 : 0] bypass_rs1, bypass_rs2;
    assign bypass_rs1 = (o_pipe_M.wb_control.is_write_back && (o_pipe_M.wb_control.rdf == select_rs1)) ? o_pipe_M.alu_result :
                        (o_pipe_W.wb_control.is_write_back && (o_pipe_W.wb_control.rdf == select_rs1)) ? o_pipe_W.alu_result :
                        (o_pipe_WC.wb_control.is_write_back && (o_pipe_WC.wb_control.rdf == select_rs1)) ? o_pipe_WC.mux_result :
                        o_pipe_A.rs1;
    assign bypass_rs2 = (o_pipe_M.wb_control.is_write_back && (o_pipe_M.wb_control.rdf == select_rs2)) ? o_pipe_M.alu_result :
                        (o_pipe_W.wb_control.is_write_back && (o_pipe_W.wb_control.rdf == select_rs2)) ? o_pipe_W.alu_result :
                        (o_pipe_WC.wb_control.is_write_back && (o_pipe_WC.wb_control.rdf == select_rs2)) ? o_pipe_WC.mux_result :
                        o_pipe_A.rs2;

    // Arithmetic Logic Unit
    alu ALU (
        .clk(clk),
        .rst(rst),

        .i_control(o_pipe_A.alu_control),
        .i_rs1(bypass_rs1), // bypass
        .i_rs2(bypass_rs2), // bypass
        .i_imm(o_pipe_A.imm),
        .i_pc(o_pipe_A.pc),

        .o_result(alu_result),
        .o_zero(alu_flag_zero),
        .o_less_than(alu_flag_less_than)
    );

    // MUX
    // selects between ALU result and compare result depending on use_flag
    assign i_pipe_M.alu_result = o_pipe_A.use_flag ? alu_flag_less_than : alu_result;

    // Multiply Divide Unit
    mdu MDU (
        .clk(clk),
        .rst(rst),

        .i_control(o_pipe_A.mdu_control),
        .i_rs1(o_pipe_A.rs1),
        .i_rs2(o_pipe_A.rs2),

        .o_result(i_pipe_M.mdu_result)
    );

    // Comparator
    cmp CMP (
        .clk(clk),
        .rst(rst),

        .i_control(o_pipe_A.cmp_control),
        .i_alu_flag_zero(alu_flag_zero),
        .i_alu_flag_less_than(alu_flag_less_than),

        .o_branch(cmp_branch)
    );  

// PIPE_M ===============================================================
// Pipeline register for Memory stage
    pipe #(
        .CABLE_T(cable_pipe_M_t)
    ) PIPE_M (
        .clk(clk),
        .rst(rst),
        .enable(),

        .i_pipe(i_pipe_M),

        .o_pipe(o_pipe_M)
    );

    // Data Memory Engine - Data Cache - TLB interface
    dme DME #(
        .TLB_LINES(),
        .CACHE_SECTORS(),
        .CACHE_LINES(),
        .CACHE_BYTES(),
        .STB_LINES(),
        .REG_WIDTH(),
        .VA_WIDTH(),
        .PA_WIDTH(),
        .ID_WIDTH()
    ) DME (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),

        .i_control(o_pipe_M.mem_control),
        .i_virtual_addr(o_pipe_A.alu_result),
        .i_write_data(o_pipe_A.rs2),

        .o_data_loaded(i_pipe_W.mem_data),
        .o_exeption(),
        .o_stall(),

        // tlb write
        .i_write_enable(),
        .i_physical_addr(),

        // mem
        .o_mem_enable(mem_data_enable),
        .o_mem_addr(mem_data_enable),
        .o_mem_data(mem_data_store),
        .o_mem_write(mem_data_write),
        .o_mem_ack(mem_data_ack),

        .i_mem_enable(),
        .i_mem_data(),
        .i_mem_id_request(arb_id),
        .i_mem_id_response()
    );

// PIPE_W ===============================================================
    pipe #(
        .CABLE_T(cable_pipe_W_t)
    ) PIPE_W (
        .clk(clk),
        .rst(rst),
        .enable(),

        .i_pipe(i_pipe_W),

        .o_pipe(o_pipe_W)
    );

    // MUX
    assign i_pipe_WC.mux_result = o_pipe_W.is_load ? o_pipe_W.mem_data : o_pipe_W.alu_result;

// PIPE_WC ===============================================================
    pipe #(
        .CABLE_T(cable_pipe_WC_t)
    ) PIPE_WC (
        .clk(clk),
        .rst(rst),
        .enable(),

        .i_pipe(i_pipe_WC),

        .o_pipe(o_pipe_WC)
    );

// MEMORY ===============================================================

    arb #(
        .PA_WIDTH(),
        .LINE_WIDTH(),
        .ID_WIDTH()
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
        .PA_WIDTH(),
        .LINE_WIDTH(),
        .ID_WIDTH(),
        .STAGES()
    ) MEM (
        .clk(clk),
        .rst(rst),

        .i_mem_enable(),
        .i_mem_write(),
        .i_mem_addr(),
        .i_mem_data(),
        .i_mem_id(arb_id),
        .i_mem_ack(mem_data_ack || mem_instruction_ack)

        //instruction ack?

        .o_mem_enable(),
        .o_mem_data(),
        .o_mem_id_response()
        .o_mem_full()        
    )

endmodule
