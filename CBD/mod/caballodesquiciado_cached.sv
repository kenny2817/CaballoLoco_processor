
import cmp_pkg::*;
import alu_pkg::*;
import opcodes_pkg::*;

module cbd #(
    parameter NUM_REG, REG_WIDTH,
    parameter NUM_INSTR,
    parameter TLB_LINES, CACHE_LINES, STB_LINES, N_CACHE_SECTORS, LINE_WIDTH
) (
    input logic clk,
    input logic rst
);

// LOCAL PARAMETERS =============================================================

    wire YES = 1'b1;
    wire NO = 1'b0;

    localparam REG_SELECT = $clog2(NUM_REG);
    localparam INSTR_SELECT = $clog2(NUM_INSTR);
    localparam INDEX_WIDTH = $clog2(N_CACHE_SECTORS);
    localparam OFFSET_WIDTH = $clog2(LINE_WIDTH);

// CABLE MANAGEMENT ======================================================
    // Register select paths
    logic [INSTR_SELECT -1 : 0] pc_F, pc_D, new_pc;
    logic [REG_SELECT -1 : 0] reg_a_select_D, reg_a_select_A;
    logic [REG_SELECT -1 : 0] reg_b_select_D, reg_b_select_A;
    logic [REG_SELECT -1 : 0] reg_c_select_D, reg_c_select_A, reg_c_select_M, reg_c_select_W;

    // Data paths
    logic [REG_WIDTH -1 : 0] instruction_F, instruction_D;
    wire  [REG_WIDTH -1 : 0] regs_D [NUM_REG];
    logic [REG_WIDTH -1 : 0] reg_a_D, reg_a_A;
    logic [REG_WIDTH -1 : 0] reg_b_D, reg_b_A, reg_b_M, reg_b_forwarded;
    logic [REG_WIDTH -1 : 0] a, b;
    logic [REG_WIDTH -1 : 0] offset_D, offset_A;
    logic [REG_WIDTH -1 : 0] alu_data_A, alu_data_M, alu_data_W;
    logic [REG_WIDTH -1 : 0] mem_data_M, mem_data_W;
    logic [REG_WIDTH -1 : 0] new_reg;

    // Control signals
    logic       is_write_D, is_write_A, is_write_M, is_write_W;
    logic       is_load_D, is_load_A, is_load_M, is_load_W;
    logic       is_store_D, is_store_A, is_store_M;
    logic       is_cmp_D;
    logic       cmp_data_D;
    alu_op_e    alu_op_D, alu_op_A;
    cmp_op_e    cmp_op_D;

    // Hazard and Forwarding signals
    logic       nop;
    logic       forward_a_D, forward_b_D, select_forward_a_D, select_forward_b_D;
    logic       forward_a_A, forward_b_A, select_forward_a_A, select_forward_b_A;

    // Exceptions
    logic       e_itlb_D, e_itlb_A, e_itlb_M, e_itlb_W;
    logic       e_illegal_instruction_D, e_illegal_instruction_A, e_illegal_instruction_M, e_illegal_instruction_W;
    logic       e_zero_division_D, e_zero_division_A, e_zero_division_M, e_zero_division_W;
    logic       e_dtlb_W;


// PROGRAM COUNTER
    reg_mono #(
        .DATA_WIDTH(INSTR_SELECT)
    ) PC (
        .clk(clk),
        .rst(rst),
        .i_write_enable(!nop),
        .i_write_data(new_pc),
        .o_read_data(pc_F)
    );

 assign new_pc = cmp_data_D ? (pc_D + offset_D[INSTR_SELECT -1 : 0]) : (pc_F + 1);

    // INSTRUCTIONS
    reg_bank_mono #( 
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_INSTR)
    ) INSTRUCTIONS (
        .clk(clk),
        .rst(rst),
        .i_write_enable(NO),
        .i_select(pc_F),
        .i_write_data('x),
        .o_read_data(instruction_F)
    );

// PIPE_D ===============================================================
    pipe_D #(
        .INSTR_WIDTH(REG_WIDTH),
        .PC_WIDTH(INSTR_SELECT)
    ) PIPE_D (
        .clk(clk),
        .rst(rst),
        .enable(!nop),
        .flush(cmp_data_D),

        .i_instruction(instruction_F),
        .i_pc(pc_F),
        .i_exception_itlb(NO),

        .o_instruction(instruction_D),
        .o_pc(pc_D),
        .o_exception_itlb(e_itlb_D)
    );

    // OPCODE DECODER
    opd_32 #(
        .NUM_REG(NUM_REG)
    ) OPD_32 (
        .i_instruction(instruction_D),
        .i_nop(nop),

        .o_select_a(reg_a_select_D),
        .o_select_b(reg_b_select_D),
        .o_select_c(reg_c_select_D),
        .o_is_write(is_write_D),
        .o_is_load(is_load_D),
        .o_is_store(is_store_D),
        .o_is_cmp(is_cmp_D),
        .o_cmp_op(cmp_op_D),
        .o_alu_op(alu_op_D),
        .o_offset(offset_D)
    );

    // REGISTERS
    reg_bank #(
        .DATA_WIDTH(REG_WIDTH),
        .NUM_REG(NUM_REG)
    ) REGISTERS (
        .clk(clk),
        .rst(rst),
        .i_write_enable(is_write_W),
        .i_write_select(reg_c_select_W),
        .i_write_data(new_reg),
        .o_read_data(regs_D)
    );

    // REGISTER A
    assign reg_a_D = (forward_a_D) ? 
        (select_forward_a_D ? new_reg : alu_data_M) : 
        regs_D[reg_a_select_D];
    

    // REGISTER B
    assign reg_b_D = (forward_b_D) ?
        (select_forward_b_D ? new_reg : alu_data_M) : 
        regs_D[reg_b_select_D];

    // COMPARATOR
    cmp #(
        .DATA_WIDTH(REG_WIDTH)
    ) CMP (
        .i_elemA(reg_a_D),
        .i_elemB(reg_b_D),
        .i_op(cmp_op_D),
        .o_output(cmp_data_D)
    );

// PIPE_A ===============================================================
    pipe_A #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_A (
        .clk(clk),
        .rst(rst),
        .enable(YES),
        
        .i_reg_a(reg_a_D),
        .i_reg_b(reg_b_D),
        .i_offset(offset_D),
        .i_reg_a_select(reg_a_select_D),
        .i_reg_b_select(reg_b_select_D),
        .i_reg_c_select(reg_c_select_D),
        .i_is_write(is_write_D),
        .i_is_load(is_load_D),
        .i_is_store(is_store_D),
        .i_alu_op(alu_op_D),
        .i_exception_itlb(e_itlb_D),
        .i_exception_illegal_instruction(NO),

        .o_reg_a(reg_a_A),
        .o_reg_b(reg_b_A),
        .o_offset(offset_A),
        .o_reg_a_select(reg_a_select_A),
        .o_reg_b_select(reg_b_select_A),
        .o_reg_c_select(reg_c_select_A),
        .o_is_write(is_write_A),
        .o_is_load(is_load_A),
        .o_is_store(is_store_A),
        .o_alu_op(alu_op_A),
        .o_exception_itlb(e_itlb_A),
        .o_exception_illegal_instruction(e_illegal_instruction_A)
    );

    // MUX reg_a-FORWARDING-PC
    assign a = (forward_a_A) ? (select_forward_a_A ? new_reg : alu_data_M) : reg_a_A;
    
    // MUX reg_b-FORWARDING-OFFSET
    assign reg_b_forwarded = (forward_b_A) ? (select_forward_b_A ? new_reg : alu_data_M) : reg_b_A;
    assign b = (is_store_A | is_load_A) ? offset_A : reg_b_forwarded;

    // ALU
    alu #(
        .DATA_WIDTH(REG_WIDTH)
    ) ALU (
        .i_elemA(a),
        .i_elemB(b),
        .i_op(alu_op_A),
        .o_output(alu_data_A)
    );

// PIPE_M ===============================================================
    pipe_M #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_M (
        .clk(clk),
        .rst(rst),
        .enable(YES),

        .i_reg_b(reg_b_forwarded),
        .i_alu_data(alu_data_A),
        .i_reg_c_select(reg_c_select_A),
        .i_is_write(is_write_A),
        .i_is_load(is_load_A),
        .i_is_store(is_store_A),
        .i_exception_itlb(e_itlb_A),
        .i_exception_illegal_instruction(e_illegal_instruction_A),
        .i_exception_zero_division(NO),

        .o_reg_b(reg_b_M),
        .o_alu_data(alu_data_M),
        .o_reg_c_select(reg_c_select_M),
        .o_is_write(is_write_M),
        .o_is_load(is_load_M),
        .o_is_store(is_store_M),
        .o_exception_itlb(e_itlb_M),
        .o_exception_illegal_instruction(e_illegal_instruction_M),
        .o_exception_zero_division(e_zero_division_M),
    );

    // MEMORY

    logic hit_tlb;
    logic e_tlb;
    logic [REG_WIDTH -1 : 0] addr_tlb;

    tlb #(
        .N_LINES(TLB_LINES),
        .VA_WIDTH(REG_WIDTH),
        .PA_WIDTH(REG_WIDTH)
    ) TLB (
        .clk(clk),
        .rst(rst),

        .i_virtual_addr(alu_data_M),

        .i_write_enable(NO),
        .i_write__virtual_ddr('x),
        .i_write_physical_addr('x),

        .o_hit(hit_tlb),
        .o_exeption(e_tlb),
        .o_physical_addr(addr_tlb)
    );

    logic valid_commit;
    logic [REG_WIDTH -1 : 0] data_commit;
    logic [REG_WIDTH -1 : 0] addr_commit;
    logic [REG_WIDTH -1 : 0] read_stb;
    logic hit_stb;
    logic e_stb;

    logic hit_cache;
    logic e_cache;
    logic [REG_WIDTH -1 : 0] read_cache;


    logic [REG_WIDTH -1 : 0] addr_cache;
    logic store_cache;
    assign addr_cache = is_load_M ? addr_tlb : addr_commit;
    assign store_cache = valid_commit & ~is_load_M;

    cache #(
        .N_LINES(CACHE_LINES),
        .N_SECTORS(N_CACHE_SECTORS),
        .LINE_WIDTH(LINE_WIDTH),
        .REG_WIDTH(REG_WIDTH),
        .PA_WIDTH(REG_WIDTH),
        .TAG_WIDTH(REG_WIDTH - INDEX_WIDTH - OFFSET_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH)
    ) CACHE (
        .clk(clk),
        .rst(rst),

        .i_is_store(store_cache),
        .i_write_data(data_commit),
        .i_addr(addr_cache),

        .o_hit(hit_cache),
        .o_exeption(e_cache),
        .o_read_data(read_cache)
    );

    logic hit_W = '0;
    stb #(
        .VA_WIDTH(REG_WIDTH),
        .N_LINES(STB_LINES)
    ) STB (
        .clk(clk),
        .rst(rst),

        .i_adress(addr_tlb),
        .i_write_data(reg_b_M),
        .i_is_store(is_store_M),
        .i_was_load(is_load_W),
        .i_was_hit_cache(hit_W),

        .o_hit(hit_stb),
        .o_exeption(e_stb),
        .o_read_data(read_stb),

        .o_valid_commit(valid_commit),
        .o_data_commit(data_commit),
        .o_addr_commit(addr_commit)
    );


    assign mem_data_M = hit_stb ? read_stb : read_cache;

// PIPE_W ===============================================================
    pipe_W #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) PIPE_W (
        .clk(clk),
        .rst(rst),
        .enable(YES),

        .i_mem_data(mem_data_M),
        .i_alu_data(alu_data_M),
        .i_reg_c_select(reg_c_select_M),
        .i_is_write(is_write_M),
        .i_is_load(is_load_M),
        .i_exception_itlb(e_itlb_M),
        .i_exception_illegal_instruction(e_illegal_instruction_M),
        .i_exception_zero_division(e_zero_division_M),
        .i_exception_dtlb(NO),

        .o_mem_data(mem_data_W),
        .o_alu_data(alu_data_W),
        .o_reg_c_select(reg_c_select_W),
        .o_is_write(is_write_W),
        .o_is_load(is_load_W),
        .o_exception_itlb(e_itlb_W),
        .o_exception_illegal_instruction(e_illegal_instruction_W),
        .o_exception_zero_division(e_zero_division_W),
        .o_exception_dtlb(e_dtlb_W)
    );

    // MUX ALU-MEM
    assign new_reg = is_load_W ? mem_data_W : alu_data_W;

// CTRL UNITS ==========================================================
    // HAZARD UNIT
    haz #(
        .REG_SELECT(REG_SELECT)
    ) HAZARD_UNIT (
        .i_is_cmp_D(is_cmp_D),
        .i_is_write_A(is_write_A),
        .i_is_load_D(is_load_D),
        .i_is_load_A(is_load_A),
        .i_reg_a_select_D(reg_a_select_D),
        .i_reg_b_select_D(reg_b_select_D),
        .i_reg_c_select_A(reg_c_select_A),

        .o_nop(nop)
    );

    // FORWARDING reg_a & reg_b
    fwd #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) FWD_D (
        .i_reg_a_select(reg_a_select_D),
        .i_reg_b_select(reg_b_select_D),

        .i_is_write_M(is_write_M),
        .i_reg_c_select_M(reg_c_select_M),
        .i_is_write_W(is_write_W),
        .i_reg_c_select_W(reg_c_select_W),

        .o_forward_a(forward_a_D),
        .o_select_forward_a(select_forward_a_D),
        .o_forward_b(forward_b_D),
        .o_select_forward_b(select_forward_b_D)
    );

    // FORWARDING a & b
    fwd #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) FWD_A (
        .i_reg_a_select(reg_a_select_A),
        .i_reg_b_select(reg_b_select_A),

        .i_is_write_M(is_write_M),
        .i_reg_c_select_M(reg_c_select_M),
        .i_is_write_W(is_write_W),
        .i_reg_c_select_W(reg_c_select_W),

        .o_forward_a(forward_a_A),
        .o_select_forward_a(select_forward_a_A),
        .o_forward_b(forward_b_A),
        .o_select_forward_b(select_forward_b_A)
    );

endmodule

module cbd_tb;

    // Parameters
    localparam NUM_REG = 10;
    localparam REG_WIDTH = 32;
    localparam NUM_INSTR = 11;
    localparam TLB_LINES = 4;
    localparam CACHE_LINES = 2;
    localparam STB_LINES = 4;
    localparam N_CACHE_SECTORS = CACHE_LINES;
    localparam LINE_WIDTH = 2; 

    // Local parameters
    localparam REG_SELECT = $clog2(NUM_REG);
    localparam logic [REG_SELECT-1:0] REG_0 = 0;
    localparam logic [REG_SELECT-1:0] REG_1 = 1;
    localparam logic [REG_SELECT-1:0] REG_2 = 2;
    localparam logic [REG_SELECT-1:0] REG_3 = 3;
    localparam logic [REG_SELECT-1:0] REG_4 = 4;

    // Signals
    logic clk = 0;
    logic rst;

    // DUT
    cbd #(
        .NUM_REG(NUM_REG),
        .REG_WIDTH(REG_WIDTH),
        .NUM_INSTR(NUM_INSTR),
        .TLB_LINES(TLB_LINES),
        .CACHE_LINES(CACHE_LINES),
        .STB_LINES(STB_LINES),
        .N_CACHE_SECTORS(N_CACHE_SECTORS),
        .LINE_WIDTH(LINE_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    always #5 clk = ~clk;


    initial begin
        $monitoroff;
        rst = 1; #1; rst = 0; #1;
        dut.TLB.virtual_addrs[0] = 0; dut.TLB.physical_addrs[0] = 0; dut.TLB.valid_bit[0] = 1;
        dut.TLB.virtual_addrs[1] = 1; dut.TLB.physical_addrs[1] = 2; dut.TLB.valid_bit[1] = 1;
        dut.CACHE.cache_tags[0][0] = 0; dut.CACHE.cache_valid_bit[0][0] = 1; dut.CACHE.cache_mem[0][0][0] = 1; dut.CACHE.cache_mem[0][0][1] = 3;
        dut.CACHE.cache_tags[1][0] = 0; dut.CACHE.cache_valid_bit[1][0] = 1; dut.CACHE.cache_mem[1][0][0] = 2; dut.CACHE.cache_mem[1][0][1] = 4;

        for (int i = 0; i < TLB_LINES; i++) begin
            $display("TLB Line %0d: V:%0h P:%0h Vb:%b", i, dut.TLB.virtual_addrs[i], dut.TLB.physical_addrs[i], dut.TLB.valid_bit[i]);
        end
        for (int i = 0; i < N_CACHE_SECTORS; i++) begin
            for (int j = 0; j < CACHE_LINES / N_CACHE_SECTORS; j++) begin
                $display(
                    "CACHE Sector %0d Line %0d: Tag:%0h Vb:%b Data[0]:%0h [1]:%0h", 
                    i, j, dut.CACHE.cache_tags[i][j], dut.CACHE.cache_valid_bit[i][j], 
                    dut.CACHE.cache_mem[i][j][0], dut.CACHE.cache_mem[i][j][1]
                );
            end
        end

        dut.INSTRUCTIONS.data[0] = {LW_OP,  REG_0, REG_0, REG_4, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[1] = {LW_OP,  REG_0, REG_0, REG_0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[2] = {LW_OP,  REG_0, REG_0, REG_1, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[3] = {ADD_OP, REG_1, REG_0, REG_2, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[4] = {SW_OP,  REG_1, REG_2, REG_0, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        dut.INSTRUCTIONS.data[5] = {BEQ_OP, REG_2, REG_2, REG_0, {{(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT -2){1'b0}}, 2'd1}};
        dut.INSTRUCTIONS.data[9] = {ADD_OP, REG_1, REG_0, REG_3, {(REG_WIDTH - OPCODES_WIDTH - 3 * REG_SELECT){1'b0}}};
        @(posedge clk);
        $monitoron;
        #135;
        $finish;
    end
    initial begin
        $dumpfile("cbl.vcd");
        $dumpvars(0, dut);
    end

    initial $monitor(
        "t:%3t | regs:%3d %3d %3d %3d %3d | hit:%b %b %b | e:%b %b %b | addr:%h %h - %b| c:%h - %h %h %h - %h | pc:%2d %2d | ist:%b | alu:%4d %4d : %4d | nop:%b |", 
        $time, dut.REGISTERS.data[0], dut.REGISTERS.data[1], dut.REGISTERS.data[2], dut.REGISTERS.data[3], dut.REGISTERS.data[4], 
        dut.hit_tlb, dut.hit_cache, dut.hit_stb, dut.e_tlb, dut.e_cache, dut.e_stb, 
        dut.addr_tlb, dut.addr_commit, dut.is_load_M,
        dut.CACHE.i_addr, dut.CACHE.addr_tag, dut.CACHE.addr_idx, dut.CACHE.addr_off, dut.read_cache,
        dut.pc_F, dut.pc_D, dut.instruction_D, 
        dut.a, dut.b, dut.alu_data_A,
        dut.nop, 
    );

endmodule