//*********************************************************
// IEEE STD 1364-2001 Verilog file: lib_add_sub.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org 
//*********************************************************
// N bit addition/subtraction
module lib_add_sub 
    #(parameter lpm_width = 8,
                lpm_direction = "ADD")
 (input [lpm_width-1:0] dataa,
  input [lpm_width-1:0] datab,  
  output reg [lpm_width-1:0] result);

  always @(dataa or datab)
    if (lpm_direction == "SUB")
      result <= dataa - datab;
    else
      result <= dataa + datab;

endmodule
