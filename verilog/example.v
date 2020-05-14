//*********************************************************
// IEEE STD 1364-2001 Verilog file: example.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org 
//*********************************************************
module example   //----> Interface
  #(parameter WIDTH =8)    // Bit width 
 (input  clk, // System clock
  input  reset,    // Asynchronous reset
  input  [WIDTH-1:0] a, b, op1, // Vector type inputs
  output [WIDTH-1:0] sum, // Vector type inputs
  output [WIDTH-1:0] c,  // Integer output
  output reg [WIDTH-1:0] d); // Integer output
// --------------------------------------------------------
  reg  [WIDTH-1:0]  s;         // Infer FF with always
  wire [WIDTH-1:0] op2, op3; 
  wire [WIDTH-1:0] a_in, b_in;

  assign op2 = b;       // Only one vector type in Verilog;
             // no conversion int -> logic vector necessary

  lib_add_sub add1          //----> Component instantiation
  ( .result(op3), .dataa(op1), .datab(op2));
    defparam add1.lpm_width = WIDTH;
    defparam add1.lpm_direction = "SIGNED";

  lib_ff reg1  
  ( .data(op3), .q(sum), .clock(clk));  // Used ports
    defparam reg1.lpm_width = WIDTH;

  assign c = a + b; //---->  Data flow style (concurrent)
  assign a_i = a; // Order of statement does not
  assign b_i = b; // matter in concurrent code
 
  //----> Behavioral style
  always @(posedge clk or posedge reset)  
  begin : p1             // Infer register 
    reg [WIDTH-1:0] s;
    if (reset) begin
      s = 0; d = 0;
    end else begin
      //s <= s + a_i;        // Signal assignment statement
      // d = s;
      s = s + b_i;
      d = s;
    end
  end

endmodule
