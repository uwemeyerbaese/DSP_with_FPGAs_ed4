//*********************************************************
// IEEE STD 1364-2001 Verilog file: lib_ff.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org 
//*********************************************************
// N bit register
module lib_ff
  #(parameter lpm_width =8)
  (input clock,
   input [lpm_width-1:0] data,
   output reg [lpm_width-1:0] q);

  
always @(posedge clock)
    q <= data;
    
endmodule
