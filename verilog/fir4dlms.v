//*********************************************************
// IEEE STD 1364-2001 Verilog file: fir4dlms.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// This is a generic DLMS FIR filter generator 
// It uses W1 bit data/coefficients bits
module fir4dlms         //----> Interface
 #(parameter W1 = 8,    // Input bit width
             W2 = 16,   // Multiplier bit width 2*W1
             L  = 2)    // Filter length 
  (input clk,                     // System clock
   input reset,                   // Asynchronous reset 
   input signed [W1-1:0] x_in,    //System input
   input signed [W1-1:0] d_in,    //  Reference input 
   output signed [W1-1:0] f0_out, // 1. filter coefficient
   output signed [W1-1:0] f1_out, // 2. filter coefficient  
   output signed [W2-1:0] y_out,  // System output
   output signed [W2-1:0] e_out); // Error signal
// -------------------------------------------------------- 
// 2D array types memories are supported by Quartus II
// in Verilog, use therefore single vectors
  reg signed [W1-1:0] x[0:4]; 
  reg signed [W1-1:0] f[0:1];  
  reg signed [W1-1:0] d[0:2]; // Desired signal array
  wire signed [W1-1:0] emu;
  reg signed [W2-1:0] xemu[0:1]; // Product array
  reg signed [W2-1:0] p[0:1];    // double bit width
  reg signed [W2-1:0] y, e, sxtd; 

  always @(posedge clk or posedge reset) // Store these data 
  begin: Store                          // or coefficients
    integer k;    // loop variable  
    if (reset) begin         // Asynchronous clear
      for (k=0; k<=2; k=k+1) d[k] <= 0;
      for (k=0; k<=4; k=k+1) x[k] <= 0;
      for (k=0; k<=1; k=k+1) f[k] <= 0;
    end else begin
      d[0] <= d_in; // Shift register for desired data 
      d[1] <= d[0];
      d[2] <= d[1];
      x[0] <= x_in; // Shift register for data 
      x[1] <= x[0];   
      x[2] <= x[1];
      x[3] <= x[2];
      x[4] <= x[3];
      f[0] <= f[0] + xemu[0][15:8]; // implicit divide by 2
      f[1] <= f[1] + xemu[1][15:8]; 
    end
  end

// Instantiate L pipelined multiplier
  always @(posedge clk or posedge reset) 
  begin : Mul    
    integer k, I;    // loop variable 
    if (reset) begin       // Asynchronous clear
      for (k=0; k<=L-1; k=k+1) begin
        p[k] <= 0;
        xemu[k] <= 0;
      end
      y <= 0; e <= 0;
    end else begin
      for (I=0; I<L; I=I+1) begin
        p[I] <= x[I] * f[I];
        xemu[I] <= emu * x[I+3];
      end
      y <= p[0] + p[1];  // Compute ADF output
     // Scale y by 128 because x is fraction
      e <= d[2] - (y >>> 7);
    end
  end
  
  assign emu = e >>> 1;  // e*mu divide by 2 and 
                        // 2 from xemu makes mu=1/4


  assign  y_out  = y >>> 7;    // Monitor some test signals
  assign  e_out  = e;
  assign  f0_out = f[0];
  assign  f1_out = f[1];

endmodule
