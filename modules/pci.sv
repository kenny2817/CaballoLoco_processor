module pci (
   input    logic       clk,
   input    logic       sel,
   input    logic [7:0] immediate,
   output   logic [7:0] pc
);
always_ff @ (posedge clk) begin
        if (sel)
            pc <= pc + 1;
        else
            pc <= immediate;
end
endmodule
