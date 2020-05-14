//*********************************************************
// IEEE STD 1364-2001 Verilog file: add2p.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// 22-bit adder with two pipeline stages
// uses no components     
module add2p   
#(parameter WIDTH   = 28,    // Total bit width
            WIDTH1  = 9,     // Bit width of LSBs 
            WIDTH2  = 9,     // Bit width of middle
            WIDTH12 = 18,    // Sum WIDTH1+WIDTH2
            WIDTH3  =  10)   // Bit width of MSBs
 (input  [WIDTH-1:0] x, y,   // Inputs
  output [WIDTH-1:0] sum,    // Result
  output LSBs_carry, MSBs_carry,  // Carry test bits
  input   clk);              // System clock
// --------------------------------------------------------
  reg [WIDTH1-1:0] l1, l2, v1, s1; // LSBs of inputs
  reg [WIDTH1:0]   q1;             // LSBs of inputs
  reg [WIDTH2-1:0] l3, l4, s2;     // Middle bits
  reg [WIDTH2:0]   q2, v2;         // Middle bits
  reg [WIDTH3-1:0] l5, l6, q3, v3, s3; // MSBs of input

  // Split in MSBs and LSBs and store in registers
  always @(posedge clk) begin
    // Split LSBs from input x,y
    l1[WIDTH1-1:0] <= x[WIDTH1-1:0];
    l2[WIDTH1-1:0] <= y[WIDTH1-1:0];
    // Split middle bits from input x,y
    l3[WIDTH2-1:0] <= x[WIDTH2-1+WIDTH1:WIDTH1];
    l4[WIDTH2-1:0] <= y[WIDTH2-1+WIDTH1:WIDTH1];
    // Split MSBs from input x,y
    l5[WIDTH3-1:0] <= x[WIDTH3-1+WIDTH12:WIDTH12];
    l6[WIDTH3-1:0] <= y[WIDTH3-1+WIDTH12:WIDTH12];				
//************** First stage of the adder  ****************
    q1 <= {1'b0, l1} + {1'b0, l2};  // Add LSBs of x and y
    q2 <= {1'b0, l3} + {1'b0, l4};  // Add LSBs of x and y
    q3 <= l5 + l6;                  // Add MSBs of x and y
//************* Second stage of the adder *****************
    v1 <= q1[WIDTH1-1:0];           // Save q1   
// Add result from middle bits (x+y) and carry from LSBs
    v2 <= q1[WIDTH1] + {1'b0,q2[WIDTH2-1:0]};
// Add result from MSBs bits (x+y) and carry from middle
    v3 <= q2[WIDTH2] + q3;
//************* Third stage of the adder ******************
    s1 <= v1;                             // Save v1
    s2 <= v2[WIDTH2-1:0];          // Save v2
// Add result from MSBs bits (x+y) and 2. carry from middle
    s3 <= v2[WIDTH2] + v3;
  end

  assign LSBs_carry = q1[WIDTH1]; // Provide test signals
  assign MSBs_carry = v2[WIDTH2];

// Build a single output word of WIDTH=WIDTH1+WIDTH2+WIDTH3
  assign sum ={s3, s2, s1};   // Connect sum to output pins

endmodule
