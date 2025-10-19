module haz #(
    parameter REG_SELECT
) (
    input logic i_is_cmp_0,
    input logic i_is_write_1,
    input logic i_is_load_0,
    input logic i_is_load_1,
    input logic [REG_SELECT -1 : 0] i_reg_a_select_0,
    input logic [REG_SELECT -1 : 0] i_reg_b_select_0,
    input logic [REG_SELECT -1 : 0] i_reg_c_select_1,

    output logic o_nop
);

    wire STALL = 1'b1;
    wire CHILL = 1'b0;

    always_comb begin
        // ALU-write hazard
        if  (i_is_cmp_0 && i_is_write_1 && (
            (i_reg_a_select_0 == i_reg_c_select_1) ||
            (i_reg_b_select_0 == i_reg_c_select_1))) begin
            o_nop = STALL;
        // Load-use hazard
        end else if (i_is_load_1) begin
            if (i_is_load_0) begin
                if (i_reg_a_select_0 == i_reg_c_select_1) begin
                    o_nop = STALL;
                end else begin
                    o_nop = CHILL;
                end
            end else begin
                if ((i_reg_a_select_0 == i_reg_c_select_1) || 
                    (i_reg_b_select_0 == i_reg_c_select_1)) begin
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

    logic is_cmp_0;
    logic is_write_1;
    logic is_load_0;
    logic is_load_1;
    logic [REG_SELECT -1 : 0] reg_a_select_0;
    logic [REG_SELECT -1 : 0] reg_b_select_0;
    logic [REG_SELECT -1 : 0] reg_c_select_1;

    logic nop;

    haz #(
        .REG_SELECT(REG_SELECT)
    ) DUT (
        .i_is_cmp_0(is_cmp_0),
        .i_is_write_1(is_write_1),
        .i_is_load_0(is_load_0),
        .i_is_load_1(is_load_1),
        .i_reg_a_select_0(reg_a_select_0),
        .i_reg_b_select_0(reg_b_select_0),
        .i_reg_c_select_1(reg_c_select_1),

        .o_nop(nop)
    );

    initial begin
        // Test cases for ALU-write hazard
        // Case 1.1: i_is_cmp_0, i_is_write_1, reg_a matches reg_c -> STALL
        is_cmp_0 = 1'b1; is_write_1 = 1'b1; is_load_0 = 1'b0; is_load_1 = 1'b0; reg_a_select_0 = 5; reg_b_select_0 = 6; reg_c_select_1 = 5; #10;
        
        // Case 1.2: i_is_cmp_0, i_is_write_1, reg_b matches reg_c -> STALL
        is_cmp_0 = 1'b1; is_write_1 = 1'b1; is_load_0 = 1'b0; is_load_1 = 1'b0; reg_a_select_0 = 8; reg_b_select_0 = 7; reg_c_select_1 = 7; #10;

        // Case 1.3: i_is_cmp_0, i_is_write_1, no register match -> CHILL
        is_cmp_0 = 1'b1; is_write_1 = 1'b1; is_load_0 = 1'b0; is_load_1 = 1'b0; reg_a_select_0 = 1; reg_b_select_0 = 2; reg_c_select_1 = 3; #10;

        // Test cases for Load-use hazard
        // Case 2.1: i_is_load_1, i_is_load_0, reg_a matches reg_c -> STALL
        is_cmp_0 = 1'b0; is_write_1 = 1'b0; is_load_0 = 1'b1; is_load_1 = 1'b1; reg_a_select_0 = 10; reg_b_select_0 = 11; reg_c_select_1 = 10; #10;

        // Case 2.2: i_is_load_1, i_is_load_0, no register match -> CHILL
        is_cmp_0 = 1'b0; is_write_1 = 1'b0; is_load_0 = 1'b1; is_load_1 = 1'b1; reg_a_select_0 = 10; reg_b_select_0 = 11; reg_c_select_1 = 12; #10;

        // Case 2.3: i_is_load_1, not i_is_load_0, reg_a matches reg_c -> STALL
        is_cmp_0 = 1'b0; is_write_1 = 1'b0; is_load_0 = 1'b0; is_load_1 = 1'b1; reg_a_select_0 = 15; reg_b_select_0 = 16; reg_c_select_1 = 15; #10;

        // Case 2.4: i_is_load_1, not i_is_load_0, reg_b matches reg_c -> STALL
        is_cmp_0 = 1'b0; is_write_1 = 1'b0; is_load_0 = 1'b0; is_load_1 = 1'b1; reg_a_select_0 = 17; reg_b_select_0 = 18; reg_c_select_1 = 18; #10;

        // Case 2.5: i_is_load_1, not i_is_load_0, no register match -> CHILL
        is_cmp_0 = 1'b0; is_write_1 = 1'b0; is_load_0 = 1'b0; is_load_1 = 1'b1; reg_a_select_0 = 15; reg_b_select_0 = 16; reg_c_select_1 = 17; #10;

        // Test case for no hazard
        // Case 3.1: No hazard conditions met -> CHILL
        is_cmp_0 = 1'b0; is_write_1 = 1'b0; is_load_0 = 1'b0; is_load_1 = 1'b0; reg_a_select_0 = 20; reg_b_select_0 = 21; reg_c_select_1 = 22; #10;
        
        $finish;
    end

    initial $monitor(
        "cmp:%b | wb:%b | ld:%b %b | sel:%2d %2d %2d || nop:%b",
        is_cmp_0, is_write_1, is_load_0, is_load_1, reg_a_select_0, reg_b_select_0, reg_c_select_1,
        nop
    );

endmodule