
// Import the package
import alu_pkg::*;

module alu_tb;
    localparam REG_WIDTH = 32;

    // --- Testbench Signals ---
    
    // Inputs to the module
    alu_control_t control;
    logic [REG_WIDTH-1:0] rs1;
    logic [REG_WIDTH-1:0] rs2;
    logic [REG_WIDTH-1:0] imm;
    logic [REG_WIDTH-1:0] pc;

    // Outputs from the module
    logic [REG_WIDTH-1:0] result;
    logic                 zero;
    logic                 less_than;

    // Test tracking
    integer test_count = 0;
    integer errors = 0;

    // --- Instantiate the Module Under Test (MUT) ---
    alu #(.REG_WIDTH(REG_WIDTH)) dut (
        .i_control(control),
        .i_rs1(rs1),
        .i_rs2(rs2),
        .i_imm(imm),
        .i_pc(pc),
        .o_result(result),
        .o_zero(zero),
        .o_less_than(less_than)
    );

    // --- Helper Task for Testing ---
    task apply_and_check(
        string        test_name,
        alu_control_t new_control,
        logic [REG_WIDTH-1:0] in_rs1,
        logic [REG_WIDTH-1:0] in_rs2,
        logic [REG_WIDTH-1:0] in_imm,
        logic [REG_WIDTH-1:0] in_pc,
        logic [REG_WIDTH-1:0] exp_result,
        logic                 exp_zero,
        logic                 exp_less_than,
        logic                 check_flags // Set to 1 to check flags, 0 to ignore
    );
        test_count++;
        
        // Apply stimulus
        control = new_control;
        rs1     = in_rs1;
        rs2     = in_rs2;
        imm     = in_imm;
        pc      = in_pc;
        
        // Wait for combinational logic to settle
        #1; 

        // Check the main result
        if (result !== exp_result) begin
            $display("--- [FAIL] Test %0d: %s (Result) ---", test_count, test_name);
            $display("    Result:   %h (dec: %d)", result, $signed(result));
            $display("    Expected: %h (dec: %d)", exp_result, $signed(exp_result));
            errors++;
        end

        // Conditionally check flags
        if (check_flags) begin
            if (zero !== exp_zero) begin
                $display("--- [FAIL] Test %0d: %s (Zero Flag) ---", test_count, test_name);
                $display("    Result: %b, Expected: %b", zero, exp_zero);
                errors++;
            end
            if (less_than !== exp_less_than) begin
                $display("--- [FAIL] Test %0d: %s (Less Than Flag) ---", test_count, test_name);
                $display("    Result: %b, Expected: %b", less_than, exp_less_than);
                errors++;
            end
        end

        if (errors == 0) begin
             $display("[PASS] Test %0d: %s", test_count, test_name);
        end
    endtask

    logic [REG_WIDTH-1:0] VAL_100, VAL_50, VAL_NEG_100, VAL_MAX_S, VAL_1;
    logic [REG_WIDTH-1:0] VAL_PC, VAL_IMM, MASK_F0, MASK_0F;
    alu_control_t ctrl;
    
    // --- Main Test Sequence ---
    initial begin
        $display("--- Starting ALU Testbench ---");

        // --- Test Vectors ---

        VAL_100   = 32'd100;
        VAL_50    = 32'd50;
        VAL_NEG_100 = -100;
        VAL_MAX_S = 32'h7FFFFFFF;
        VAL_1     = 32'd1;
        VAL_PC    = 32'h8000_0000;
        VAL_IMM   = 32'd123;
        MASK_F0   = 32'hF0F0F0F0;
        MASK_0F   = 32'h0F0F0F0F;

        // --- Test 1: OP_ADD ---
        ctrl = {OP_ADD, OP_REG, OP_REG, 1'b0};
        apply_and_check("ADD: 100 + 50", ctrl, VAL_100, VAL_50, '0, '0, 32'd150, 1'b0, 1'b0, 1);
        
        ctrl = {OP_ADD, OP_REG, OP_REG, 1'b0};
        apply_and_check("ADD: 100 + (-100)", ctrl, VAL_100, VAL_NEG_100, '0, '0, 32'd0, 1'b1, 1'b0, 1);
        
        ctrl = {OP_ADD, OP_REG, OP_REG, 1'b0};
        apply_and_check("ADD: Signed Overflow (MAX+1)", ctrl, VAL_MAX_S, VAL_1, '0, '0, 32'h80000000, 1'b0, 1'b0, 1);

        // --- Test 2: OP_SUB (Signed Compare) ---
        ctrl = {OP_SUB, OP_REG, OP_REG, 1'b0}; // use_unsigned = 0
        apply_and_check("SUB/Signed: 100 - 50 (A > B)", ctrl, VAL_100, VAL_50, '0, '0, 32'd50, 1'b0, 1'b0, 1);
        apply_and_check("SUB/Signed: 50 - 100 (A < B)", ctrl, VAL_50, VAL_100, '0, '0, -50, 1'b0, 1'b1, 1);
        apply_and_check("SUB/Signed: 100 - 100 (A == B)", ctrl, VAL_100, VAL_100, '0, '0, 32'd0, 1'b1, 1'b0, 1);
        apply_and_check("SUB/Signed: -100 - 50 (A < B)", ctrl, VAL_NEG_100, VAL_50, '0, '0, -150, 1'b0, 1'b1, 1);

        // --- Test 3: OP_SUB (Unsigned Compare) ---
        ctrl = {OP_SUB, OP_REG, OP_REG, 1'b1}; // use_unsigned = 1
        apply_and_check("SUB/Unsigned: 100 - 50 (A > B)", ctrl, VAL_100, VAL_50, '0, '0, 32'd50, 1'b0, 1'b0, 1);
        apply_and_check("SUB/Unsigned: 50 - 100 (A < B)", ctrl, VAL_50, VAL_100, '0, '0, -50, 1'b0, 1'b1, 1);
        apply_and_check("SUB/Unsigned: 100 - 100 (A == B)", ctrl, VAL_100, VAL_100, '0, '0, 32'd0, 1'b1, 1'b0, 1);
        // Special case: signed -100 is a large unsigned number
        apply_and_check("SUB/Unsigned: -100 - 50 (A > B)", ctrl, VAL_NEG_100, VAL_50, '0, '0, 32'hFFFFFF9C - 32'd50, 1'b0, 1'b0, 1);

        // --- Test 4: Logic Ops (Flags not checked) ---
        ctrl = {OP_AND, OP_REG, OP_REG, 1'b0};
        apply_and_check("AND: F0F0F0F0 & 0F0F0F0F", ctrl, MASK_F0, MASK_0F, '0, '0, 32'h00000000, 'x, 'x, 0);
        
        ctrl = {OP_OR, OP_REG, OP_REG, 1'b0};
        apply_and_check("OR: F0F0F0F0 | 0F0F0F0F", ctrl, MASK_F0, MASK_0F, '0, '0, 32'hFFFFFFFF, 'x, 'x, 0);

        ctrl = {OP_XOR, OP_REG, OP_REG, 1'b0};
        apply_and_check("XOR: F0F0F0F0 ^ 0F0F0F0F", ctrl, MASK_F0, MASK_0F, '0, '0, 32'hFFFFFFFF, 'x, 'x, 0);

        // --- Test 5: Shift Ops (Flags not checked) ---
        ctrl = {OP_SLL, OP_REG, OP_REG, 1'b0};
        apply_and_check("SLL: 0x1 << 5", ctrl, VAL_1, 32'd5, '0, '0, 32'd32, 'x, 'x, 0);
        
        ctrl = {OP_SRL, OP_REG, OP_REG, 1'b0};
        apply_and_check("SRL: 0xF0000000 >> 4", ctrl, 32'hF0000000, 32'd4, '0, '0, 32'h0F000000, 'x, 'x, 0);

        ctrl = {OP_SRA, OP_REG, OP_REG, 1'b0};
        apply_and_check("SRA: 0xF0000000 >> 4", ctrl, 32'hF0000000, 32'd4, '0, '0, 32'hFF000000, 'x, 'x, 0);

        // // --- Test 6: MUX Selectors (Flags not checked) ---
        ctrl = {OP_ADD, OP_PC, OP_IMM, 1'b0};
        apply_and_check("MUX: PC + IMM", ctrl, '0, '0, VAL_IMM, VAL_PC, VAL_PC + VAL_IMM, 'x, 'x, 0);

        ctrl = {OP_ADD, OP_REG, OP_IMM, 1'b0};
        apply_and_check("MUX: RS1 + IMM", ctrl, VAL_1, '0, VAL_IMM, '0, VAL_1 + VAL_IMM, 'x, 'x, 0);

        ctrl = {OP_ADD, OP_REG, OP_ZERO, 1'b0};
        apply_and_check("MUX: RS1 + 0", ctrl, VAL_100, '0, '0, '0, VAL_100, 'x, 'x, 0);
        
        ctrl = {OP_ADD, OP_ZERO, OP_REG, 1'b0};
        apply_and_check("MUX: 0 + RS2", ctrl, '0, VAL_50, '0, '0, VAL_50, 'x, 'x, 0);

        // --- Final Report ---
        #10;
        if (errors == 0) begin
            $display("--- All %0d Tests Passed! ---", test_count);
        end else begin
            $display("--- !!! FAILED: %0d / %0d Tests !!! ---", errors, test_count);
        end
        
        $finish;
    end

endmodule