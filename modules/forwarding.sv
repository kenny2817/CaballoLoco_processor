module fwd #(
    parameter REG_WIDTH,
    parameter REG_SELECT
) (
    input logic [REG_SELECT -1 : 0] i_reg_a_select,
    input logic [REG_SELECT -1 : 0] i_reg_b_select,

    input logic i_is_write_M,
    input logic [REG_SELECT -1 : 0] i_reg_c_select_M,

    input logic i_is_write_W,
    input logic [REG_SELECT -1 : 0] i_reg_c_select_W,

    output logic o_forward_a,
    output logic o_select_forward_a, // 0: from MEM stage, 1: from WB stage

    output logic o_forward_b, 
    output logic o_select_forward_b // 0: from MEM stage, 1: from WB stage
);
    // FORWARD A
    always_comb begin
        if (i_is_write_M && (i_reg_a_select == i_reg_c_select_M)) begin // load is managed by hazard unit
            o_forward_a = 1'b1;
            o_select_forward_a = 1'b0;
        end else if (i_is_write_W && (i_reg_a_select == i_reg_c_select_W)) begin
            o_forward_a = 1'b1;
            o_select_forward_a = 1'b1;
        end else begin
            o_forward_a = 1'b0;
            o_select_forward_a = 'x;
        end
    end
    
    // FORWARD B
    always_comb begin
        if (i_is_write_M && (i_reg_b_select == i_reg_c_select_M)) begin // load is managed by hazard unit
            o_forward_b = 1'b1;
            o_select_forward_b = 1'b0;
        end else if (i_is_write_W && (i_reg_b_select == i_reg_c_select_W)) begin
            o_forward_b = 1'b1;
            o_select_forward_b = 1'b1;
        end else begin
            o_forward_b = 1'b0;
            o_select_forward_b = 'x;
        end
    end
    
endmodule

module fwd_tb;
    
    localparam REG_WIDTH = 32;
    localparam REG_SELECT = 5;

    logic [REG_SELECT -1 : 0] reg_a_select;
    logic [REG_SELECT -1 : 0] reg_b_select;

    logic is_write_M;
    logic [REG_SELECT -1 : 0] reg_c_select_M;
    
    logic is_write_W;
    logic [REG_SELECT -1 : 0] reg_c_select_W;

    logic forward_a;
    logic select_forward_a;

    logic forward_b;
    logic select_forward_b;

    fwd #(
        .REG_WIDTH(REG_WIDTH),
        .REG_SELECT(REG_SELECT)
    ) DUT (
        .i_reg_a_select(reg_a_select),
        .i_reg_b_select(reg_b_select),
        .i_is_write_M(is_write_M),
        .i_reg_c_select_M(reg_c_select_M),
        .i_is_write_W(is_write_W),
        .i_reg_c_select_W(reg_c_select_W),
        .o_forward_a(forward_a),
        .o_select_forward_a(select_forward_a),
        .o_forward_b(forward_b),
        .o_select_forward_b(select_forward_b)
    );

    initial begin
        // No forwarding
        reg_a_select = 1; reg_b_select = 2; is_write_M = 0; reg_c_select_M = 0; is_write_W = 0; reg_c_select_W = 0; #10;
        is_write_M = 1; reg_c_select_M = 3; is_write_W = 1; reg_c_select_W = 4; #10;

        // Forward A from MEM (stage 2)
        reg_a_select = 5; reg_b_select = 6; is_write_M = 1; reg_c_select_M = 5; is_write_W = 0; reg_c_select_W = 0; #10;
        
        // Forward A from WB (stage 3)
        reg_a_select = 7; reg_b_select = 8; is_write_M = 0; reg_c_select_M = 0; is_write_W = 1; reg_c_select_W = 7; #10;
        
        // Forward B from MEM (stage 2)
        reg_a_select = 9; reg_b_select = 10; is_write_M = 1; reg_c_select_M = 10; is_write_W = 0; reg_c_select_W = 0; #10;

        // Forward B from WB (stage 3)
        reg_a_select = 11; reg_b_select = 12; is_write_M = 0; reg_c_select_M = 0; is_write_W = 1; reg_c_select_W = 12; #10;

        // Priority: MEM over WB for A
        reg_a_select = 13; reg_b_select = 14; is_write_M = 1; reg_c_select_M = 13; is_write_W = 1; reg_c_select_W = 13; #10;

        // Priority: MEM over WB for B
        reg_a_select = 15; reg_b_select = 16; is_write_M = 1; reg_c_select_M = 16; is_write_W = 1; reg_c_select_W = 16; #10;

        // Forward A from MEM, B from WB
        reg_a_select = 17; reg_b_select = 18; is_write_M = 1; reg_c_select_M = 17; is_write_W = 1; reg_c_select_W = 18; #10;

        // Forward A from WB, B from MEM
        reg_a_select = 19; reg_b_select = 20; is_write_M = 1; reg_c_select_M = 20; is_write_W = 1; reg_c_select_W = 19; #10;

        // Forward A and B from MEM
        reg_a_select = 21; reg_b_select = 22; is_write_M = 1; reg_c_select_M = 21; is_write_W = 0; reg_c_select_W = 0; #10;
        reg_c_select_M = 22; #10; // B matches now
        reg_a_select = 22; #10; // A and B match same source

        // Forward A and B from WB
        reg_a_select = 23; reg_b_select = 24; is_write_M = 0; reg_c_select_M = 0; is_write_W = 1; reg_c_select_W = 23; #10;
        reg_c_select_W = 24; #10; // B matches now
        reg_a_select = 24; #10; // A and B match same source

        $finish;
    end

    initial $monitor(
        "t: %4t | sel: %2d %2d | 2: %b %2d | 3: %b %2d || a: %b %b | b: %b %b |",
        $time, reg_a_select, reg_b_select, is_write_M, reg_c_select_M, is_write_W, reg_c_select_W,
        forward_a, select_forward_a, forward_b, select_forward_b
    );

endmodule