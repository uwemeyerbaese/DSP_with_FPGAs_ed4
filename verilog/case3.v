//*********************************************************
// IEEE STD 1364-2001 Verilog file: case3.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module case3
  (input  [2:0] table_in,  // Three bit 
  output reg [2:0] table_out); // Range 0 to 6
// --------------------------------------------------------
// This is the DA CASE table for
// the 3 coefficients: 2, 3, 1  

  always @(table_in)
  begin
    case (table_in)
      0 :     table_out =  0;
      1 :     table_out =  2;
      2 :     table_out =  3;
      3 :     table_out =  5;
      4 :     table_out =  1;
      5 :     table_out =  3;
      6 :     table_out =  4;
      7 :     table_out =  6;
      default : ;
    endcase
  end

endmodule