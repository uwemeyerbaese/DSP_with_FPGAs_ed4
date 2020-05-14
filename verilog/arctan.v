//*********************************************************
// IEEE STD 1364-2001 Verilog file: arctan.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
// --------------------------------------------------------
module arctan  #(parameter W = 9,    // Bit width
                          L  = 5)    // Array size
  (input clk,                 // System clock
   input reset,               // Asynchron reset
   input signed [W-1:0] x_in,  // System input
   //output reg signed [W-1:0] d_o [1:L],
   output wire signed [W-1:0] d_o1, d_o2 ,d_o3, d_o4 ,d_o5,
                                    // Auxiliary recurrence
   output reg signed [W-1:0] f_out); // System output
// --------------------------------------------------------
  reg signed [W-1:0] x;   // Auxilary signals
  wire signed [W-1:0] f;  
  wire signed [W-1:0] d [1:L]; // Auxilary array
  // Chebychev coefficients c1, c2, c3 for 8 bit precision 
  // c1 = 212; c3 = -12; c5 = 1;

  always @(posedge clk or posedge reset) begin 
    if (reset) begin  // Asynchronous clear
      x <= 0; f_out <= 0;
    end else begin
      x <= x_in;     // FF for input and output
      f_out <= f; 
    end  
  end 
  
    // Compute sum-of-products with
    // Clenshaw's recurrence formula
  assign d[5] = 'sd1;   // c5=1
  assign d[4] = (x * d[5]) / 128;
  assign d[3] = ((x * d[4]) / 128) - d[5] - 12; // c3=-12
  assign d[2] = ((x * d[3]) / 128) - d[4];
  assign d[1] = ((x * d[2]) / 128) - d[3] + 212; // c1=212
  assign f    = ((x * d[1]) / 256) - d[2]; 
                                  // last step is different
  
  assign d_o1 = d[1];  // Provide test signals as outputs
  assign d_o2 = d[2];  
  assign d_o3 = d[3];  
  assign d_o4 = d[4];  
  assign d_o5 = d[5]; 
endmodule
