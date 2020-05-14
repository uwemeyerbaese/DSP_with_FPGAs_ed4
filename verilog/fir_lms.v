//*********************************************************
// IEEE STD 1364-2001 Verilog file: fir_lms.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// This is a generic LMS FIR filter generator 
// It uses W1 bit data/coefficients bits
module fir_lms          //----> Interface
 #(parameter W1 = 8,    // Input bit width
             W2 = 16,   // Multiplier bit width 2*W1
             L  = 2,    // Filter length 
             Delay = 3) // Pipeline steps of multiplier
  (input clk,                     // System clock
   input reset,                   // Asynchronous reset 
   input signed [W1-1:0] x_in,    //System input
   input signed [W1-1:0] d_in,    //  Reference input 
   output signed [W1-1:0] f0_out, // 1. filter coefficient
   output signed [W1-1:0] f1_out, // 2. filter coefficient  
   output signed [W2-1:0] y_out,  // System output
   output signed [W2-1:0] e_out); // Error signal
// -------------------------------------------------------- 
// Signed data types are supported in 2001
// Verilog, and used whenever possible
  reg signed [W1-1:0] x [0:1]; // Data array 
  reg signed [W1-1:0] f [0:1]; // Coefficient array 
  reg signed [W1-1:0] d;
  wire signed [W1-1:0] emu;
  reg signed [W2-1:0] p [0:1]; // 1. Product array 
  reg signed [W2-1:0] xemu [0:1]; // 2. Product array 
  wire signed [W2-1:0]  y, sxty, e, sxtd; 
  wire signed [W2-1:0] sum;  // Auxilary signals
 
  always @(posedge clk or posedge reset) 
  begin: Store          // Store these data or coefficients
    if (reset) begin       // Asynchronous clear
      d <= 0; x[0] <= 0; x[1] <= 0; f[0] <= 0; f[1] <= 0;      
    end else begin
      d <= d_in; // Store desired signal in register 
      x[0] <= x_in; // Get one data sample at a time 
      x[1] <= x[0];   // shift 1
      f[0] <= f[0] + xemu[0][15:8]; // implicit divide by 2
      f[1] <= f[1] + xemu[1][15:8]; 
    end    
  end

// Instantiate L multiplier
  always @(*) 
  begin : MulGen1    
    integer I;    // loop variable 
    for (I=0; I<L; I=I+1) p[I] <= x[I] * f[I];
  end

  assign y = p[0] + p[1];  // Compute ADF output

  // Scale y by 128 because x is fraction
  assign e = d - (y >>> 7) ;
  assign emu = e >>> 1;  // e*mu divide by 2 and 
                        // 2 from xemu makes mu=1/4

// Instantiate L multipliers
  always @(*) 
  begin : MulGen2    
    integer I;    // loop variable 
      for (I=0; I<=L-1; I=I+1) xemu[I] <= emu * x[I];
  end

  assign  y_out  = y >>> 7; // Monitor some test signals
  assign  e_out  = e;
  assign  f0_out = f[0];
  assign  f1_out = f[1];

endmodule