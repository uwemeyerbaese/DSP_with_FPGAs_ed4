//*********************************************************
// IEEE STD 1364-2001 Verilog file: lfsr.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module lfsr          //----> Interface
  (input clk,        // System clock
   input reset,      // Asynchronous reset 
   output [6:1] y);  // System output
// --------------------------------------------------------
  reg [6:1] ff; // Note that reg is keyword in Verilog and 
                               // can not be variable name
  integer i;  // loop variable
        
  always @(posedge clk or posedge reset) 
  begin // Length 6 LFSR with xnor    
    if (reset)          // Asynchronous clear
      ff <= 0;
    else begin
      ff[1] <= ff[5] ~^ ff[6];//Use non-blocking assignment
      for (i=6; i>=2 ; i=i-1)//Tapped delay line: shift one 
        ff[i] <= ff[i-1];
    end
  end

  assign   y = ff;         // Connect to I/O pins

endmodule