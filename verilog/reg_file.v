//*********************************************************
// IEEE STD 1364-2001 Verilog file: reg_file.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// Desciption: This is a W x L bit register file.
module reg_file  #(parameter W = 7, // Bit width - 1
                        N  = 15) // Number of registers - 1
  (input clk,           // System clock
   input  reset,        // Asynchronous reset       
   input reg_ena,       // Write enable active 1
   input [W:0] data,    // System input
   input [3:0]  rd,     // Address for write
   input [3:0]  rs,     // 1. read address 
   input [3:0]  rt,     // 2. read address 
   output reg [W:0] s,  // 1. data
   output reg [W:0] t); // 2. data
// -------------------------------------------------------- 
  reg [W:0] r [0:N];
  
  always @(posedge clk or posedge reset)
  begin : MUX              // Input mux inferring registers
    integer k;    // loop variable  
    if (reset)          // Asynchronous clear
      for (k=0; k<=N; k=k+1) r[k] <= 0;
    else if ((reg_ena == 1) && (rd > 0)) 
      r[rd] <= data; 
  end 

  //  2 output demux without registers
  always @*
  begin : DEMUX
    if (rs > 0) // First source
      s = r[rs];
    else
      s = 0;
    if (rt > 0) // Second source
      t = r[rt];
    else
      t = 0;
  end
                 
endmodule
