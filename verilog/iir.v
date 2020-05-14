//*********************************************************
// IEEE STD 1364-2001 Verilog file: iir.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module iir #(parameter W = 14) // Bit width - 1
  (input  clk,                 // System clock
   input reset,                // Asynchronous reset    
   input  signed [W:0] x_in,   // System input
   output signed [W:0] y_out); // System output  
// --------------------------------------------------------  
  reg signed [W:0] x, y;

// Use FFs for input and recursive part 
always @(posedge clk or posedge reset)    
  if (reset) begin           // Note: there is a signed
    x <= 0; y <= 0;          // integer in Verilog 2001
  end else begin
    x  <= x_in;                  
    y  <= x + (y >>> 1) + (y >>> 2); // >>> uses less LEs
    // y  <= x + y / 'sd2 + y / 'sd4; // same as /2 and /4
    //y  <= x + y / 2 + y / 4; // div with / uses more LEs
    //y <= x + {y[W],y[W:1]}+ {y[W],y[W],y[W:2]};
  end

                               
assign  y_out = y;           // Connect y to output pins

endmodule
