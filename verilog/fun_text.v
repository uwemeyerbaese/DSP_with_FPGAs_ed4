//*********************************************************
// IEEE STD 1364-2001 Verilog file: fun_text.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
//  A 32 bit function generator using accumulator and ROM
// --------------------------------------------------------
module fun_text             //----> Interface
  #(parameter WIDTH = 32) // Bit width
 (input  clk,             // System clock
  input  reset,           // Asynchronous reset
  input  [WIDTH-1:0]  M,  // Accumulator increment
  output reg [7:0]  sin,      // System sine output
  output [7:0]  acc);     // Accumulator MSBs
// --------------------------------------------------------
  reg [WIDTH-1:0] acc32;
  wire [7:0]    msbs;               // Auxiliary vectors
  reg [7:0] rom[255:0];

  always @(posedge clk or posedge reset)    
      if (reset == 1)  
        acc32 <= 0;
      else begin    
        acc32 <= acc32 + M; //-- Add M to acc32 and 
      end                   //-- store in register
    
  assign msbs = acc32[WIDTH-1:WIDTH-8];
  assign acc  = msbs;

  initial
  begin
	$readmemh("sine256x8.txt", rom);
  end

  always @ (posedge clk)
  begin
    sin <= rom[msbs];
  end

endmodule