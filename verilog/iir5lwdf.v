//*********************************************************
// IEEE STD 1364-2001 Verilog file: iir5lwdf.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// Description: 5 th order Lattice Wave Digital Filter 
// Coefficients gamma: 
// 0.988739 -0.000519 -1.995392 -0.000275 -1.985016 
// --------------------------------------------------------
module iir5lwdf                   //-----> Interface
  (input clk,                     // System clock
   input reset,                   // Asynchronous reset
   input signed [31:0] x_in,      // System input 
   output signed [31:0] y_ap1out, // AP1 out
   output signed [31:0] y_ap2out, // AP2 out
   output signed [31:0] y_ap3out, // AP3 out
   output signed [31:0] y_out);   // System output
// --------------------------------------------------------
// Internal signals have 7.15 format
  reg signed [21:0] c1, c2, c3, l2, l3; 
  reg signed [21:0] a4, a5, a6, a8, a9, a10; 
  reg signed [21:0] x, ap1, ap2, ap3, ap3r, y;

// Products have double bit width
  reg signed [41:0] p1, a4g2, a4g3, a8g4, a8g5;

//Coefficients gamma use 5*4=20 bits and are scaled by 2^15
  wire signed [19:0] g1, g2, g3, g4, g5;
  assign  g1 = 20'h07E8F; //  0.988739
  assign  g2 = 20'h00011; // (-)0.000519
  assign  g3 = 20'h0FF69; // (-)1.995392
  assign  g4 = 20'h00009; // (-)0.000275
  assign  g5 = 20'h0FE15; // (-)1.985016 

  always @(posedge clk or posedge reset)
  begin : P1  
    if (reset) begin             // Asynchronous clear
      c1 <= 0; ap1 <= 0; c2 <= 0; l2 <= 0;
      ap2 <= 0; c3 <= 0; l3 <= 0; ap3 <= 0;
      ap3r <= 0; y <= 0; x <= 0; 
    end else begin  // AP LWDF form
    // Redefine 16.16 input bits as internal precision
    // in 7.15 format, i.e. 20 bits
      x <= x_in[22:1]; 
// 1. AP section is 1. order
      p1 =   g1 * (c1 - x);
      c1 <= x + (p1 >>> 15);
      ap1 <= c1 + (p1 >>> 15);
// 2. AP section is 2. order
      a4 = ap1 - l2 + c2 ;
      a4g2 = a4 * g2;
      a5 = c2 - (a4g2 >>> 15); // was +
      a4g3 = a4 * g3;
      a6 = -(a4g3 >>> 15) - l2; // was +
      c2 <= a5;
      l2 <= a6;
      ap2 <= -a5 - a6 - a4;
// 3. AP section is 2. order
      a8 = x - l3 + c3;
      a8g4 = a8 * g4;
      a9 = c3 - (a8g4 >>> 15); // was +
      a8g5 = a8 * g5;
      a10 = -(a8g5 >>> 15)  - l3; // was +
      c3 <= a9;
      l3 <= a10;
      ap3 <= -a9 - a10 - a8;
      ap3r <= ap3; // extra register due to AP1
// Output adder
      y <= ap3r + ap2; 
    end
  end 
  
// change 15 to 16 bit fraction, i.e. add 1 LSBs
// Redefine bits as 32 bit SLV 1+22+9=32
  assign  y_out   = {{9{y[21]}},y,1'b0};
  assign y_ap1out = {{9{ap1[21]}},ap1,1'b0}; 
  assign y_ap2out = {{9{ap2[21]}},ap2,1'b0}; 
  assign y_ap3out = {{9{ap3r[21]}},ap3r,1'b0}; 

endmodule
