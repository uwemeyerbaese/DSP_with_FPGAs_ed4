//*********************************************************
// IEEE STD 1364-2001 Verilog file: ccmul.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
//`include "220model.v"

module ccmul #(parameter W2 = 17,   // Multiplier bit width
                         W1 = 9,    // Bit width c+s sum
                         W  = 8)    // Input bit width 
 (input clk,  // Clock for the output register
  input signed [W-1:0] x_in, y_in, c_in,  // Inputs
  input signed [W1-1:0]  cps_in, cms_in,  // Inputs
  output reg signed [W-1:0]    r_out, i_out);  // Results


  wire signed [W-1:0] x, y, c ;       // Inputs and outputs
  wire signed [W2-1:0] r, i, cmsy, cpsx, xmyc, sum; //Prod.
  wire signed [W1-1:0] xmy, cps, cms, sxtx, sxty;//x-y etc.


  wire  clken, cr1, ovl1, cin1, aclr, ADD, SUB; 
                                       // Auxiliary signals
  assign cin1=0; assign aclr=0; assign ADD=1; assign SUB=0; 
  assign cr1=0; assign sum=0; assign clken=0;
                                         // Default for add
  assign x   = x_in;   // x 
  assign y   = y_in;   // j * y
  assign c   = c_in;   // cos
  assign cps = cps_in; // cos + sin
  assign cms = cms_in; // cos - sin

  always @(posedge clk) begin
    r_out <= r[W2-3:W-1];      // Scaling and FF for output
    i_out <= i[W2-3:W-1];   
  end

//********* ccmul with 3 mul. and 3 add/sub  **************
  assign sxtx  = x;     // Possible growth for 
  assign sxty  = y;     // sub_1 -> sign extension

  lpm_add_sub sub_1                  // Sub:  x - y
  ( .result(xmy), .dataa(sxtx), .datab(sxty));// Used ports
//  .add_sub(SUB), .cout(cr1), .overflow(ovl1), .cin(cin1),  
//   .clken(clken), .clock(clk), .aclr(aclr));  // Unused 
    defparam sub_1.lpm_width = W1;  
    defparam sub_1.lpm_representation = "SIGNED";
    defparam sub_1.lpm_direction = "sub";

  lpm_mult mul_1                // Multiply  (x-y)*c = xmyc
  ( .dataa(xmy), .datab(c), .result(xmyc)); // Used ports
//  .sum(sum), .clock(clk), .clken(clken), .aclr(aclr)); 
                                            // Unused ports
    defparam mul_1.lpm_widtha = W1;  
    defparam mul_1.lpm_widthb = W;
    defparam mul_1.lpm_widthp = W2;  
    defparam mul_1.lpm_widths = W2;
    defparam mul_1.lpm_representation = "SIGNED";

  lpm_mult mul_2                 // Multiply (c-s)*y = cmsy
  ( .dataa(cms), .datab(y), .result(cmsy)); // Used ports 
//  .sum(sum), .clock(clk), .clken(clken), .aclr(aclr)); 
                                            // Unused ports
    defparam mul_2.lpm_widtha = W1;  
    defparam mul_2.lpm_widthb = W;
    defparam mul_2.lpm_widthp = W2;  
    defparam mul_2.lpm_widths = W2;
    defparam mul_2.lpm_representation = "SIGNED";

  lpm_mult mul_3                 // Multiply (c+s)*x = cpsx
  ( .dataa(cps), .datab(x), .result(cpsx)); // Used ports
//  .sum(sum), .clock(clk), .clken(clken), .aclr(aclr));  
                                            // Unused ports
    defparam mul_3.lpm_widtha= W1;  
    defparam mul_3.lpm_widthb = W;
    defparam mul_3.lpm_widthp = W2;  
    defparam mul_3.lpm_widths = W2;
    defparam mul_3.lpm_representation = "SIGNED";

  lpm_add_sub add_1        // Add:  r <= (x-y)*c + (c-s)*y
  ( .dataa(cmsy), .datab(xmyc), .result(r));  // Used ports
//  .add_sub(ADD), .cout(cr1), .overflow(ovl1), .cin(cin1),  
//  .clken(clken), .clock(clk), .aclr(aclr));  // Unused 
    defparam add_1.lpm_width = W2;  
    defparam add_1.lpm_representation = "SIGNED";
    defparam add_1.lpm_direction = "add";

  lpm_add_sub sub_2          // Sub: i <= (c+s)*x - (x-y)*c
  ( .dataa(cpsx), .datab(xmyc), .result(i));  // Used ports
// .add_sub(SUB), .cout(cr1), .overflow(ovl1), .clock(clk),
//  .cin(cin1),  .clken(clken), .aclr(aclr));  // Unused 
    defparam sub_2.lpm_width = W2;  
    defparam sub_2.lpm_representation = "SIGNED";
    defparam sub_2.lpm_direction = "sub";

endmodule