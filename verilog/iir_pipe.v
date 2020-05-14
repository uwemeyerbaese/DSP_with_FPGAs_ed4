//*********************************************************
// IEEE STD 1364-2001 Verilog file: iir_pipe.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module iir_pipe                 //----> Interface
 #(parameter W = 14)            // Bit width - 1
 (input clk,                    // System clock
  input reset,                  // Asynchronous reset   
  input signed [W:0]  x_in,     // System input
  output signed [W:0]  y_out);  // System output
// -------------------------------------------------------- 
  reg signed [W:0] x, x3, sx;
  reg signed [W:0] y, y9;  
            
  always @(posedge clk or posedge reset)  // Infer FFs for 
  begin               // input, output and pipeline stages;
      if (reset) begin   // Asynchronous clear
      x <= 0; x3 <= 0; sx <= 0; y9 <= 0; y <= 0; 
    end else begin
      x   <= x_in;       // use non-blocking FF assignments
      x3  <= (x >>> 1) + (x >>> 2); 
                              // i.e. x / 2 + x / 4 = x*3/4
      sx  <= x + x3;//Sum of x element i.e. output FIR part
      y9  <= (y >>> 1) + (y >>> 4); 
                            // i.e. y / 2 + y / 16 = y*9/16
      y   <= sx + y9;                     // Compute output
    end
  end

  assign y_out = y ;   // Connect register y to output pins

endmodule
