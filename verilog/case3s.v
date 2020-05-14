//*********************************************************
// IEEE STD 1364-2001 Verilog file: case3s.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module case3s
 (input  [2:0] table_in,  // Three bit 
  output reg [3:0] table_out); // Range -2 to 4 -> 4 bits
// --------------------------------------------------------
// This is the DA CASE table for
// the 3 coefficients: -2, 3, 1  

  always @(table_in)
  begin
    case (table_in)
      0 :     table_out =  0;
      1 :     table_out =  -2;
      2 :     table_out =  3;
      3 :     table_out =  1;
      4 :     table_out =  1;
      5 :     table_out =  -1;
      6 :     table_out =  4;
      7 :     table_out =  2;
      default : ;
    endcase
  end

endmodule