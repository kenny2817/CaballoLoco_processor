module haz #(
    parameter REG_SELECT
) (
    input logic i_is_cmp_D,
    input logic i_is_write_A,
    input logic i_is_load_D,
    input logic i_is_load_A,
    input logic [REG_SELECT -1 : 0] i_reg_a_select_D,
    input logic [REG_SELECT -1 : 0] i_reg_b_select_D,
    input logic [REG_SELECT -1 : 0] i_reg_c_select_A,

    output logic o_nop
);

    wire STALL = 1'b1;
    wire CHILL = 1'b0;

    always_comb begin
        // ALU-write hazard
        if  (i_is_cmp_D && i_is_write_A && (
            (i_reg_a_select_D == i_reg_c_select_A) ||
            (i_reg_b_select_D == i_reg_c_select_A))) begin
            o_nop = STALL;
        // Load-use hazard
        end else if (i_is_load_A) begin
            if (i_is_load_D) begin
                if (i_reg_a_select_D == i_reg_c_select_A) begin
                    o_nop = STALL;
                end else begin
                    o_nop = CHILL;
                end
            end else begin
                if ((i_reg_a_select_D == i_reg_c_select_A) || 
                    (i_reg_b_select_D == i_reg_c_select_A)) begin
                    o_nop = STALL;
                end else begin
                    o_nop = CHILL;
                end
            end
        end else begin
            o_nop = CHILL;
        end
    end
    
endmodule

module haz_tb;

    localparam REG_SELECT = 5;

    logic is_cmp_D;
    logic is_write_A;
    logic is_load_D;
    logic is_load_A;
    logic [REG_SELECT -1 : 0] reg_a_select_D;
    logic [REG_SELECT -1 : 0] reg_b_select_D;
    logic [REG_SELECT -1 : 0] reg_c_select_A;

    logic nop;

    haz #(
        .REG_SELECT(REG_SELECT)
    ) DUT (
        .i_is_cmp_D(is_cmp_D),
        .i_is_write_A(is_write_A),
        .i_is_load_D(is_load_D),
        .i_is_load_A(is_load_A),
        .i_reg_a_select_D(reg_a_select_D),
        .i_reg_b_select_D(reg_b_select_D),
        .i_reg_c_select_A(reg_c_select_A),

        .o_nop(nop)
    );

    initial begin
        // Test cases for ALU-write hazard
        // Case 1.1: i_is_cmp_D, i_is_write_A, reg_a matches reg_c -> STALL
        is_cmp_D = 1'b1; is_write_A = 1'b1; is_load_D = 1'b0; is_load_A = 1'b0; reg_a_select_D = 5; reg_b_select_D = 6; reg_c_select_A = 5; #10;
        
        // Case 1.2: i_is_cmp_D, i_is_write_A, reg_b matches reg_c -> STALL
        is_cmp_D = 1'b1; is_write_A = 1'b1; is_load_D = 1'b0; is_load_A = 1'b0; reg_a_select_D = 8; reg_b_select_D = 7; reg_c_select_A = 7; #10;

        // Case 1.3: i_is_cmp_D, i_is_write_A, no register match -> CHILL
        is_cmp_D = 1'b1; is_write_A = 1'b1; is_load_D = 1'b0; is_load_A = 1'b0; reg_a_select_D = 1; reg_b_select_D = 2; reg_c_select_A = 3; #10;

        // Test cases for Load-use hazard
        // Case 2.1: i_is_load_A, i_is_load_D, reg_a matches reg_c -> STALL
        is_cmp_D = 1'b0; is_write_A = 1'b0; is_load_D = 1'b1; is_load_A = 1'b1; reg_a_select_D = 10; reg_b_select_D = 11; reg_c_select_A = 10; #10;

        // Case 2.2: i_is_load_A, i_is_load_D, no register match -> CHILL
        is_cmp_D = 1'b0; is_write_A = 1'b0; is_load_D = 1'b1; is_load_A = 1'b1; reg_a_select_D = 10; reg_b_select_D = 11; reg_c_select_A = 12; #10;

        // Case 2.3: i_is_load_A, not i_is_load_D, reg_a matches reg_c -> STALL
        is_cmp_D = 1'b0; is_write_A = 1'b0; is_load_D = 1'b0; is_load_A = 1'b1; reg_a_select_D = 15; reg_b_select_D = 16; reg_c_select_A = 15; #10;

        // Case 2.4: i_is_load_A, not i_is_load_D, reg_b matches reg_c -> STALL
        is_cmp_D = 1'b0; is_write_A = 1'b0; is_load_D = 1'b0; is_load_A = 1'b1; reg_a_select_D = 17; reg_b_select_D = 18; reg_c_select_A = 18; #10;

        // Case 2.5: i_is_load_A, not i_is_load_D, no register match -> CHILL
        is_cmp_D = 1'b0; is_write_A = 1'b0; is_load_D = 1'b0; is_load_A = 1'b1; reg_a_select_D = 15; reg_b_select_D = 16; reg_c_select_A = 17; #10;

        // Test case for no hazard
        // Case 3.1: No hazard conditions met -> CHILL
        is_cmp_D = 1'b0; is_write_A = 1'b0; is_load_D = 1'b0; is_load_A = 1'b0; reg_a_select_D = 20; reg_b_select_D = 21; reg_c_select_A = 22; #10;
        
        $finish;
    end

    initial $monitor(
        "cmp:%b | wb:%b | ld:%b %b | sel:%2d %2d %2d || nop:%b",
        is_cmp_D, is_write_A, is_load_D, is_load_A, reg_a_select_D, reg_b_select_D, reg_c_select_A,
        nop
    );

endmodule