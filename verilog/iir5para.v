//*********************************************************
// IEEE STD 1364-2001 Verilog file: iir5para.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// Description: 5 th order IIR parallel form implementation 
// Coefficients: 
// D =   0.00030357
// B1 =  0.0031   -0.0032    0
// A1 =  1.0000   -1.9948    0.9959
// B2 = -0.0146    0.0146    0
// A2 =  1.0000   -1.9847    0.9852
// B3 =  0.0122
// A3 =  0.9887
// --------------------------------------------------------
module iir5para                 // I/O data in 16.16 format
  (input clk,                   // System clock
   input reset,                 // Asynchron reset
   input signed [31:0] x_in,    // System input 
   output signed [31:0] y_Dout, // 0 order
   output signed [31:0] y_1out, // 1. order
   output signed [31:0] y_21out,// 2. order 1
   output signed [31:0] y_22out,// 2. order 2
   output signed [31:0] y_out); // System output
// --------------------------------------------------------
// Internal type has 2 bits integer and 18 bits fraction:
reg signed [19:0] s11, r13, r12; // 1. BiQuad regs.
reg signed [19:0] s21, r23, r22; // 2. BiQuad regs.
reg signed [19:0] r32, r41, r42, r43, y; 
reg signed [19:0]  x;

// Products have double bit width
reg signed [39:0] b12x, b11x , a13r12, a12r12; // 1. BiQuad
reg signed [39:0] b22x, b21x, a23r22, a22r22; // 2. BiQuad
reg signed [39:0] b31x, a32r32, Dx; 

// All coefficients use 6*4=24 bits and are scaled by 2^18
wire signed [19:0] a12, a13, b11, b12; // First BiQuad  
wire signed [19:0] a22, a23, b21, b22; // Second BiQuad 
wire signed [19:0] a32, b31, D; // First order and direct
// First BiQuad coefficients
  assign a12 = 20'h7FAB9;  // (-)1.99484680
  assign a13 = 20'h3FBD0;  // 0.99591112
  assign b11 = 20'h00340;  // 0.00307256
  assign b12 = 20'h00356;  // (-)0.00316061
// Second BiQuad coefficients  
  assign  a22 = 20'h7F04F;   // (-)1.98467605
  assign  a23 = 20'h3F0E4;   // 0.98524428
  assign  b21 = 20'h00F39;   // (-)0.01464265
  assign  b22 = 20'h00F38;   // 0.01464684
// First order system with R(5) and P(5)
  assign  a32 = 20'h3F468;   // 0.98867974  
  assign  b31 = 20'h00C76;   // 0.012170
// Direct system   
  assign    D = 20'h0004F;   // 0.000304
 
  always @(posedge clk or posedge reset)
  begin : P1  
    if (reset) begin             // Asynchronous clear
      b12x <= 0; s11 <= 0; r13 <= 0; r12 <= 0;
      b22x <= 0; s21 <= 0; r23 <= 0; r22 <= 0;
      b31x <= 0; r32 <= 0; r41 <= 0;
      r42 <= 0; r43 <= 0; y <= 0; x <= 0;
    end else begin             // SOS Modified BiQuad form
  // redefine bits as FIX 16.16 number to 
      x <= {x_in[17:0], 2'b00}; 
 // internal precision 2.19 format, i.e. 21 bits
// 1. BiQuad is 2. order
      b12x <= b12 * x;
      b11x = b11 * x; 
      s11 <= (b11x >>> 18) - (b12x >>> 18); // was +
      a13r12 = a13 * r12;
      r13 <= s11 - (a13r12 >>> 18);
      a12r12 = a12 * r12;
      r12 <= r13 + (a12r12 >>> 18); // was -
// 2. BiQuad is 2. order
      b22x <= b22 * x;
      b21x = b21 * x;
      s21 <= (b22x >>> 18) - (b21x >>> 18); // was +
      a23r22 = a23 * r22;
      r23 <= s21 - (a23r22 >>> 18);
      a22r22 = a22 * r22;
      r22 <= r23 + (a22r22 >>> 18);  // was -
// 3. Section is 1. order
      b31x <= b31 * x;
      a32r32 = a32 * r32;
      r32 <= (b31x >>> 18) + (a32r32 >>> 18);
// 4. Section is assign 
      Dx = D * x;
      r41 <=   Dx >>> 18;
// Output adder tree
      r42 <= r41;
      r43 <= r42 + r32;
      y <= r12 + r22 + r43;
    end
  end 

// Change 19 to 16 bit fraction, i.e. cut 2 LSBs
// Redefine bits as 32 bit SLV
  assign y_out   = {{14{y[19]}},y[19:2]};
  assign y_Dout  = {{14{r42[19]}},r42[19:2]};  
  assign y_1out  = {{14{r32[19]}},r32[19:2]};  
  assign y_21out = {{14{r22[19]}},r22[19:2]};  
  assign y_22out = {{14{r12[19]}},r12[19:2]};
  
endmodule
