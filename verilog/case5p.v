//*********************************************************
// IEEE STD 1364-2001 Verilog file: case5p.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module case5p
 (input        clk,
  input  [4:0] table_in,
  output reg [4:0] table_out);     // range 0 to 25
// --------------------------------------------------------  
  reg [3:0] lsbs;
  reg [1:0] msbs0;
  reg [4:0] table0out00, table0out01;

// These are the distributed arithmetic CASE tables for
// the 5 coefficients: 1, 3, 5, 7, 9

  always @(posedge clk) begin
    lsbs[0] = table_in[0];
    lsbs[1] = table_in[1];
    lsbs[2] = table_in[2];
    lsbs[3] = table_in[3];
    msbs0[0] = table_in[4];
    msbs0[1] = msbs0[0];
  end 

// This is the final DA MPX stage.
  always @(posedge clk) begin 
    case (msbs0[1])
      0 : table_out <= table0out00;
      1 : table_out <= table0out01;
      default : ;
    endcase
  end

// This is the DA CASE table 00 out of 1.
  always @(posedge clk) begin 
    case (lsbs) 
      0  : table0out00 = 0;
      1  : table0out00 = 1;
      2  : table0out00 = 3;
      3  : table0out00 = 4;
      4  : table0out00 = 5;
      5  : table0out00 = 6;
      6  : table0out00 = 8;
      7  : table0out00 = 9;
      8  : table0out00 = 7;
      9  : table0out00 = 8;
      10 : table0out00 = 10;
      11 : table0out00 = 11;
      12 : table0out00 = 12;
      13 : table0out00 = 13;
      14 : table0out00 = 15;
      15 : table0out00 = 16;
      default ;
    endcase  
  end             

// This is the DA CASE table 01 out of 1.
  always @(posedge clk) begin 
    case (lsbs)
      0  : table0out01 = 9;
      1  : table0out01 = 10;
      2  : table0out01 = 12;
      3  : table0out01 = 13;
      4  : table0out01 = 14;
      5  : table0out01 = 15;
      6  : table0out01 = 17;
      7  : table0out01 = 18;
      8  : table0out01 = 16;
      9  : table0out01 = 17;
      10 : table0out01 = 19;
      11 : table0out01 = 20;
      12 : table0out01 = 21;
      13 : table0out01 = 22;
      14 : table0out01 = 24;
      15 : table0out01 = 25;
      default ;
    endcase      
  end              

endmodule