//*********************************************************
// IEEE STD 1364-2001 Verilog file: dapara.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
`include "case3s.v" // User defined component

module dapara                  //----> Interface
 (input         clk,          // System clock
   input reset,               // Asynchron reset
  input signed [3:0]  x_in,   // System input
  output reg signed[6:0]  y); // System output
// --------------------------------------------------------
  reg signed  [2:0] x [0:3];
  wire signed [3:0] h [0:3];
  reg  signed [4:0] s0, s1;
  reg  signed [3:0] t0, t1, t2, t3;

  always @(posedge clk or posedge reset)  
  begin : DA                 //----> DA in behavioral style
    integer k,l;
    if (reset) begin  // Asynchronous clear
      for (k=0; k<=3; k=k+1) x[k] <= 0;             
      y <= 0;
      t0 <= 0; t1 <= 0; t2 <= 0; t3 <= 0; s0 <= 0; s1 <= 0;
    end else begin
      for (l=0; l<=3; l=l+1) begin     // For all 4 vectors
        for (k=0; k<=1; k=k+1) begin   // shift all bits
          x[l][k] <= x[l][k+1];
        end
      end
      for (k=0; k<=3; k=k+1) begin // Load x_in in the
        x[k][2] <= x_in[k];        // MSBs of the registers
      end
  y <= h[0] + (h[1] <<< 1) + (h[2] <<< 2) - (h[3] <<< 3);
// Sign extensions, pipeline register, and adder tree:
//      t0 <= h[0]; t1 <= h[1]; t2 <= h[2]; t3 <= h[3];   
//      s0 <= t0 + (t1 <<< 1);  
//      s1 <= t2 - (t3 <<< 1);
//      y  <= s0 + (s1 <<< 2);
    end
  end

  genvar i;// Need to declare loop variable in Verilog 2001
  generate      //   One table for each bit in x_in
    for (i=0; i<=3; i=i+1) begin:LC_Tables 
      case3s LC_Table0 ( .table_in(x[i]), .table_out(h[i]));
    end
  endgenerate

endmodule