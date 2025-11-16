module cmp_tb;
    // Import the package
    import cmp_pkg::*;

    // --- Testbench Signals ---
    logic         clk; // Not needed for combinational, but good practice
    
    // Inputs to the module
    cmp_control_t control;
    logic         alu_flag_zero;
    logic         alu_flag_less_than;

    // Output from the module
    logic         branch_out;

    // Test tracking
    integer       test_count = 0;
    integer       errors = 0;

    // --- Instantiate the Module Under Test (MUT) ---
    cmp dut (
        .i_control(control),
        .i_alu_flag_zero(alu_flag_zero),
        .i_alu_flag_less_than(alu_flag_less_than),
        .o_branch(branch_out)
    );

    // --- Helper Task for Testing ---
    // This task applies stimulus and checks the result
    task apply_and_check(
        string        test_name,
        cmp_control_t new_control,
        logic         zero_flag,
        logic         less_than_flag,
        logic         expected_branch
    );
        test_count++;
        
        // Apply stimulus
        control            = new_control;
        alu_flag_zero      = zero_flag;
        alu_flag_less_than = less_than_flag;
        
        // Wait for combinational logic to settle
        #1; 

        // Check the result
        if (branch_out !== expected_branch) begin
            // Manually convert enum to string for better compatibility
            string op_name;
            case (new_control.operation)
                OP_BEQ: op_name = "OP_BEQ";
                OP_BNE: op_name = "OP_BNE";
                OP_BLT: op_name = "OP_BLT";
                OP_BGE: op_name = "OP_BGE";
                default: op_name = "???";
            endcase

            $display("--- [FAIL] Test %2d: %s ---", test_count, test_name);
            $display("    Flags: Zero=%b, LessThan=%b", zero_flag, less_than_flag);
            $display("    Control: Enable=%b, Op=%s", new_control.enable, op_name);
            $display("    Result: %b, Expected: %b", branch_out, expected_branch);
            errors++;
        end else begin
            $display("[PASS] Test %2d: %s (Z=%b, LT=%b) -> Branch=%b", 
                test_count, test_name, zero_flag, less_than_flag, branch_out);
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        cmp_control_t temp_control; // Temporary struct for broader compatibility

        $display("--- Starting CMP Testbench ---");
        
        temp_control.enable = 1'b1;

        // --- Test Case 1: BEQ (Branch if Equal) ---
        // BEQ should only be true if Zero flag is 1
        temp_control.operation = OP_BEQ;
        apply_and_check("BEQ \t | Zero=1 (rs1 == rs2)", temp_control, 1'b1, 1'b0, 1'b1);
        apply_and_check("BEQ \t | Zero=0 (rs1 != rs2)", temp_control, 1'b0, 1'b0, 1'b0);
        apply_and_check("BEQ \t | Zero=0 (rs1 < rs2)", temp_control, 1'b0, 1'b1, 1'b0);

        // --- Test Case 2: BNE (Branch if Not Equal) ---
        // BNE should only be true if Zero flag is 0
        temp_control.operation = OP_BNE;
        apply_and_check("BNE \t | Zero=1 (rs1 == rs2)", temp_control, 1'b1, 1'b0, 1'b0);
        apply_and_check("BNE \t | Zero=0 (rs1 != rs2)", temp_control, 1'b0, 1'b0, 1'b1);
        apply_and_check("BNE \t | Zero=0 (rs1 < rs2)", temp_control, 1'b0, 1'b1, 1'b1);
        
        // --- Test Case 3: BLT (Branch if Less Than) ---
        // BLT should only be true if LessThan flag is 1
        temp_control.operation = OP_BLT;
        apply_and_check("BLT \t | LessThan=1 (rs1 < rs2)", temp_control, 1'b0, 1'b1, 1'b1);
        apply_and_check("BLT \t | LessThan=0 (rs1 > rs2)", temp_control, 1'b0, 1'b0, 1'b0);
        apply_and_check("BLT \t | LessThan=0 (rs1 == rs2)", temp_control, 1'b1, 1'b0, 1'b0);

        // --- Test Case 4: BGE (Branch if Greater or Equal) ---
        // BGE should be true if LessThan is 0 OR Zero is 1
        temp_control.operation = OP_BGE;
        apply_and_check("BGE \t | (rs1 > rs2) [LT=0, Z=0]", temp_control, 1'b0, 1'b0, 1'b1);
        apply_and_check("BGE \t | (rs1 == rs2) [LT=0, Z=1]", temp_control, 1'b1, 1'b0, 1'b1);
        apply_and_check("BGE \t | (rs1 < rs2) [LT=1, Z=0]", temp_control, 1'b0, 1'b1, 1'b0);
        
        // --- Test Case 5: Disabled ---
        // Output should always be 0 if enable is low, regardless of flags
        $display("--- Testing Disabled State ---");
        temp_control.enable = 1'b0;
        temp_control.operation = OP_BEQ;
        apply_and_check("DISABLED | BEQ",  temp_control, 1'b1, 1'b0, 1'b0);
        temp_control.operation = OP_BNE;
        apply_and_check("DISABLED | BNE",  temp_control, 1'b0, 1'b0, 1'b0);
        temp_control.operation = OP_BLT;
        apply_and_check("DISABLED | BLT",  temp_control, 1'b0, 1'b1, 1'b0);
        temp_control.operation = OP_BGE;
        apply_and_check("DISABLED | BGE",  temp_control, 1'b0, 1'b0, 1'b0);

        // --- Final Report ---
        #10;
        if (errors == 0) begin
            $display("--- All %2d Tests Passed! ---", test_count);
        end else begin
            $display("--- !!! FAILED: %2d | %0d Tests !!! ---", errors, test_count);
        end
        
        $finish;
    end

endmodule