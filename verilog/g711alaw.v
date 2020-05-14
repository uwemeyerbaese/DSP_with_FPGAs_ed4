//*********************************************************
// IEEE STD 1364-2001 Verilog file: cmoms.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// G711 includes A and mu-law coding for speech signals:
//  A ~= 87.56; |x|<= 4095, i.e., 12 bit plus sign
//  mu~=255; |x|<=8160, i.e., 14 bit
// --------------------------------------------------------
module g711alaw #(parameter WIDTH = 13)  // Bit width
  (input clk,                 // System clock
   input reset,               // Asynchron reset
   input signed [12:0] x_in, // System input 
   output reg signed [7:0] enc,     //  Encoder output
   output reg signed [12:0] dec,// Decoder output
   output signed [13:0] err);  // Error of results
// --------------------------------------------------------
  wire s;
  wire signed [12:0] x; // Auxiliary vectors
  wire signed [12:0] dif;  
// --------------------------------------------------------  
  assign s = x_in[WIDTH -1]; // sign magnitude not 2C!
  assign x = {1'b0,x_in[WIDTH-2:0]};                  
  assign dif = dec - x_in;  // Difference
  assign err = (dif>0)? dif : -dif; // Absolute error 
// --------------------------------------------------------
  always @*
  begin : Encode      // Mini floating-point format encoder
    if ((x>=0) && (x<=63)) 
      enc <= {s,2'b00,x[5:1]}; // segment 1
    else  if ((x>=64) && (x<=127))
      enc <= {s,3'b010,x[5:2]}; // segment 2
    else  if ((x>=128) && (x<=255)) 
      enc <= {s,3'b011,x[6:3]}; // segment 3
    else  if ((x>=256) && (x<=511)) 
      enc <= {s,3'b100,x[7:4]}; // segment 4
    else  if ((x>=512) && (x<=1023)) 
      enc <= {s,3'b101,x[8:5]}; // segment 5
    else  if ((x>=1024) && (x<=2047)) 
      enc <= {s,3'b110,x[9:6]}; // segment 6
    else  if ((x>=2048) && (x<=4095))
      enc <= {s,3'b111,x[10:7]}; // segment 7
    else  enc <= {s,7'b0000000}; // + or - 0
  end
// --------------------------------------------------------  
  always @*
  begin  : Decode // Mini floating point format decoder
    case (enc[6:4])
      3'b000  : dec <= {s,6'b000000,enc[4:0],1'b1};
      3'b010  : dec <= {s,6'b000001,enc[3:0],2'b10};
      3'b011  : dec <= {s,5'b00001,enc[3:0],3'b100};
      3'b100  : dec <= {s,4'b0001,enc[3:0],4'b1000};
      3'b101  : dec <= {s,3'b001,enc[3:0],5'b10000};
      3'b110  : dec <= {s,2'b01,enc[3:0],6'b100000};
      default : dec <= {s,1'b1,enc[3:0],7'b1000000};
    endcase
  end
             
endmodule
