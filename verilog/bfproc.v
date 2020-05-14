//*********************************************************
// IEEE STD 1364-2001 Verilog file: bfproc.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
//`include "220model.v"
//`include "ccmul.v"

module bfproc #(parameter W2 = 17,  // Multiplier bit width
                          W1 = 9,    // Bit width c+s sum
                          W  = 8)    // Input bit width 
 (input clk,  // Clock for the output register
  input signed [W-1:0] Are_in, Aim_in,      // 8-bit inputs
  input signed [W-1:0] Bre_in, Bim_in, c_in,// 8-bit inputs
  input signed [W1-1:0]  cps_in, cms_in,  // coefficients
  output reg signed [W-1:0]  Dre_out, Dim_out,// registered
  output signed   [W-1:0]  Ere_out, Eim_out);  // results 
                                      
  reg signed [W-1:0] dif_re, dif_im;      // Bf out
  reg signed [W-1:0] Are, Aim, Bre, Bim;  // Inputs integer
  reg signed [W-1:0] c;                   // Input
  reg signed [W1-1:0] cps, cms;           // Coefficient in
            
  always @(posedge clk)   // Compute the additions of the 
  begin                   // butterfly using integers 
    Are     <= Are_in;    // and store inputs
    Aim     <= Aim_in;    // in flip-flops 
    Bre     <= Bre_in;
    Bim     <= Bim_in;
    c       <= c_in;            // Load from memory cos
    cps     <= cps_in;          // Load from memory cos+sin
    cms     <= cms_in;          // Load from memory cos-sin
    Dre_out <= (Are >>> 1) + (Bre >>> 1); // Are/2 + Bre/2
    Dim_out <= (Aim >>> 1) + (Bim >>> 1); // Aim/2 + Bim/2
  end                                 
   
     // No FF because butterfly difference "diff" is not an
  always @(*)                                // output port
  begin 
    dif_re = (Are >>> 1) - (Bre >>> 1);//i.e. Are/2 - Bre/2
    dif_im = (Aim >>> 1) - (Bim >>> 1);//i.e. Aim/2 - Bim/2
  end                                 
  
  //*** Instantiate the complex twiddle factor multiplier
  ccmul ccmul_1                    // Multiply (x+jy)(c+js)
  ( .clk(clk), .x_in(dif_re), .y_in(dif_im),  .c_in(c), 
    .cps_in(cps), .cms_in(cms), .r_out(Ere_out), 
                                          .i_out(Eim_out));
                      
endmodule