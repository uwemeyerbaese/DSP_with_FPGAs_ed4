//*********************************************************
// IEEE STD 1364-2001 Verilog file: prog_rom.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// Initialize the ROM with $readmemh. Put the memory 
// contents in the file trisc0fac.txt.  Without this file,
// this design will not compile. See Verilog 
// LRM 1364-2001 Section 17.2.8 for details on the
// format of this file.
module prog_rom
#(parameter DATA_WIDTH=12, parameter ADDR_WIDTH=8)
  (input  clk,                       // System clock
   input  reset,                     // Asynchronous reset
   input [(ADDR_WIDTH-1):0] address, // Address input
   output reg [(DATA_WIDTH-1):0] q); // Data output
// --------------------------------------------------------
// Declare the ROM variable
  reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

  initial
  begin
    $readmemh("trisc0fac.txt", rom);
  end

  always @ (posedge clk or posedge reset)
    if (reset)
      q <= 0;
    else
      q <= rom[address];

endmodule