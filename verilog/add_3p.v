//*********************************************************
// IEEE STD 1364-2001 Verilog file: add_3p.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// 29-bit adder with three pipeline stage
// uses no components     

//`include "220model.v"

module add_3p
#(parameter WIDTH    = 29, // Total bit width
            WIDTH0   = 7,  // Bit width of LSBs 
            WIDTH1   = 7,  // Bit width of 2. LSBs 
            WIDTH01  = 14, // Sum WIDTH0+WIDTH1
            WIDTH2   = 7,  // Bit width of 2. MSBs
            WIDTH012 = 21,  // Sum WIDTH0+WIDTH1+WIDTH2
            WIDTH3   =  8)  // Bit width of MSBs
 (input  [WIDTH-1:0] x, y,  // Inputs
  output [WIDTH-1:0] sum,  // Result
  output LSBs_Carry, Middle_Carry, MSBs_Carry, // Test pins
  input              clk);  // Clock

  reg [WIDTH0-1:0] l0, l1, r0, v0, s0;    // LSBs of inputs
  reg [WIDTH0:0] q0;                      // LSBs of inputs
  reg [WIDTH1-1:0] l2, l3, r1, s1;      // 2. LSBs of input
  reg [WIDTH1:0] v1, q1;                // 2. LSBs of input
  reg [WIDTH2-1:0] l4, l5, s2, h7;          // 2. MSBs bits 
  reg [WIDTH2:0] q2, v2, r2;                // 2. MSBs bits
  reg [WIDTH3-1:0] l6, l7, q3, v3, r3, s3, h8; 
                                           // MSBs of input
      
always @(posedge clk) begin
// Split in MSBs and LSBs and store in registers
  // Split LSBs from input x,y
  l0[WIDTH0-1:0] <= x[WIDTH0-1:0];
  l1[WIDTH0-1:0] <= y[WIDTH0-1:0];
  // Split 2. LSBs from input x,y
  l2[WIDTH1-1:0] <= x[WIDTH1-1+WIDTH0:WIDTH0];
  l3[WIDTH1-1:0] <= y[WIDTH1-1+WIDTH0:WIDTH0];
  // Split 2. MSBs from input x,y
  l4[WIDTH2-1:0] <= x[WIDTH2-1+WIDTH01:WIDTH01];
  l5[WIDTH2-1:0] <= y[WIDTH2-1+WIDTH01:WIDTH01];
  // Split MSBs from input x,y
  l6[WIDTH3-1:0] <= x[WIDTH3-1+WIDTH012:WIDTH012];
  l7[WIDTH3-1:0] <= y[WIDTH3-1+WIDTH012:WIDTH012];

//************* First stage of the adder  *****************
  q0 <= {1'b0, l0} + {1'b0, l1};  // Add LSBs of x and y
  q1 <= {1'b0, l2} + {1'b0, l3};  // Add 2. LSBs of x / y
  q2 <= {1'b0, l4} + {1'b0, l5};  // Add 2. MSBs of x/y
  q3 <= l6 + l7;                  // Add MSBs of x and y
//************* Second stage of the adder *****************
  v0 <= q0[WIDTH0-1:0];           // Save q0   
// Add result from 2. LSBs (x+y) and carry from LSBs 
  v1 <= q0[WIDTH0] + {1'b0, q1[WIDTH1-1:0]};
// Add result from 2. MSBs (x+y) and carry from 2. LSBs  
  v2 <= q1[WIDTH1] + {1'b0, q2[WIDTH2-1:0]};
// Add result from MSBs (x+y) and carry from 2. MSBs 
  v3 <= q2[WIDTH2] + q3;

//************** Third stage of the adder *****************
  r0 <= v0;  // Delay for LSBs
  r1 <= v1[WIDTH1-1:0];  // Delay for 2. LSBs
// Add result from 2. MSBs (x+y) and carry from 2. LSBs 
  r2 <= v1[WIDTH1] + {1'b0, v2[WIDTH2-1:0]};                                        
// Add result from MSBs (x+y) and carry from 2. MSBs
  r3 <= v2[WIDTH2] + v3;
//************ Fourth stage of the adder ******************
  s0 <= r0;              // Delay for LSBs
  s1 <= r1;              // Delay for 2. LSBs
  s2 <= r2[WIDTH2-1:0];  // Delay for 2. MSBs
// Add result from MSBs (x+y) and carry from 2. MSBs 
  s3 <= r2[WIDTH2] + r3;    
end

assign LSBs_Carry   = q0[WIDTH1];  // Provide test signals
assign Middle_Carry = v1[WIDTH1];
assign MSBs_Carry   = r2[WIDTH2];   

// Build a single output word of 
// WIDTH = WIDTH0 + WIDTH1 + WIDTH2 + WIDTH3
assign sum = {s3, s2, s1, s0}; // Connect sum to output

endmodule
