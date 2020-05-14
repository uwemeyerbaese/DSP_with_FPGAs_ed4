//*********************************************************
// IEEE STD 1364-2001 Verilog file: data_ram.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module data_ram 
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=8)
  (input  clk,                      // System clock
   input we,                        // Write emable
   input [DATA_WIDTH-1:0] data,     // Data input
   input [ADDR_WIDTH-1:0] address,  // Read/write address
   output [DATA_WIDTH-1:0] q);      // Data output
// --------------------------------------------------------
// Declare the RAM variable
  reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

// Variable to hold the registered read address
  reg [ADDR_WIDTH-1:0] addr_reg;

  always @ (posedge clk)
  begin
    if (we)    // Write
      ram[address] <= data;

    addr_reg <= address; // Synchronous memory, i.e. store 
  end                    // address in register

  assign q = ram[addr_reg];

endmodule