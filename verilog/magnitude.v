//*********************************************************
// IEEE STD 1364-2001 Verilog file:  magnitude.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module magnitude
  (input clk,                 // System clock
   input reset,               // Asynchron reset
   input signed [15:0] x, y,  // System input 
   output reg signed [15:0] r);   // System output
// --------------------------------------------------------
  reg signed [15:0] x_r, y_r, ax, ay, mi, ma;
  // approximate the magnitude via 
  // r = alpha*max(|x|,|y|) + beta*min(|x|,|y|)
  // use alpha=1 and beta=1/4

  always @(posedge reset or posedge clk) // Control the                          
    if (reset) begin       // system sample at clk rate
      x_r  <= 0; y_r <= 0;  // Asynchronous clear
    end else begin 
      x_r <= x; y_r <= y;
    end
    
    always @* begin
    ax = (x_r>=0)? x_r : -x_r; // take absolute values first
    ay = (y_r>=0)? y_r : -y_r; 
    
    if (ax > ay) begin   // Determine max and min values
      mi = ay;
      ma = ax;
    end else begin 
      mi = ax;
      ma = ay;
    end
    end
    
    always @(posedge reset or posedge clk)
    if (reset)              // Asynchronous clear
      r  <= 0;
    else
      r <= ma + mi/4; // compute r=alpha*max+beta*min  
  
endmodule
