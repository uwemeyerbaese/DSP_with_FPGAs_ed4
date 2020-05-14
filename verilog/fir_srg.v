//*********************************************************
// IEEE STD 1364-2001 Verilog file: fir_srg.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module fir_srg                 //----> Interface
  (input clk,                  // System clock
   input reset,                // Asynchronous reset 
   input signed [7:0] x,       // System input
   output reg signed [7:0] y); //  System output
// -------------------------------------------------------- 
// Tapped delay line array of bytes
  reg  signed  [7:0] tap [0:3]; 
  integer I; // Loop variable
           
  always @(posedge clk or posedge reset)  
  begin : P1                       //----> Behavioral Style
   // Compute output y with the filter coefficients weight.
   // The coefficients are [-1  3.75  3.75  -1]. 
   // Multiplication and division can
   // be done in Verilog 2001 with signed shifts. 
    if (reset) begin             // Asynchronous clear
      for (I=0; I<=3; I=I+1) tap[I] <= 0;
      y <= 0;
    end else begin    
      y <= (tap[1] <<< 1) + tap[1] + (tap[1] >>> 1)- tap[0]
           + ( tap[1] >>> 2) + (tap[2] <<< 1) + tap[2]
           + (tap[2] >>> 1) + (tap[2] >>> 2) - tap[3];

      for (I=3; I>0; I=I-1) begin  
        tap[I] <= tap[I-1]; // Tapped delay line: shift one
      end
      tap[0] <= x;   // Input in register 0
    end
  end

endmodule
