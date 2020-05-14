//*********************************************************
// IEEE STD 1364-2001 Verilog file: darom.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
//`include "220model.v"

module darom  //--> Interface
 (input         clk, reset,
  input  [2:0]  x_in0, x_in1, x_in2,
  output [2:0]  lut,
  output reg [5:0]  y);

  reg    [2:0]  x0, x1, x2;
  wire   [2:0]  table_in, table_out;

  reg [5:0] p;  // Temporary register
  wire ena;

  assign ena=1; 

  assign table_in[0] = x0[0];
  assign table_in[1] = x1[0];
  assign table_in[2] = x2[0];

  always @(posedge clk or posedge reset)  
  begin : DA                 //----> DA in behavioral style
    parameter s0=0, s1=1;
    reg [0:0] state;
    reg [1:0] count;   // Counts the shifts

    if (reset)         // Asynchronous reset
      state <= s0;
    else
      case (state) 
        s0 : begin    // Initialization
          state <= s1;
          count = 0;
          p  <= 0;           
          x0 <= x_in0;
          x1 <= x_in1;
          x2 <= x_in2;
        end
      s1 : begin                 // Processing step
          if (count == 3) begin  // Is sum of product done?
            y <= (p >> 1) + (table_out << 2);// Output to y
            state <= s0;   // and start next sum of product
          end
          else begin
            p <= (p >> 1) + (table_out << 2);
            x0[0] <= x0[1];
            x0[1] <= x0[2];
            x1[0] <= x1[1];
            x1[1] <= x1[2];
            x2[0] <= x2[1];
            x2[1] <= x2[2];
            count = count + 1;
            state <= s1;
          end
        end
        default : ;
      endcase  
  end

  lpm_rom rom_1     // Used ports:
  ( .outclock(clk),.address(table_in), .q(table_out));
// .inclock(clk),  .memenab(ena)); // Unused
    defparam rom_1.lpm_width = 3;    
    defparam rom_1.lpm_widthad = 3;
    defparam rom_1.lpm_outdata = "REGISTERED"; 
    defparam rom_1.lpm_address_control = "UNREGISTERED";
    defparam rom_1.lpm_file = "darom3.mif";

  assign lut = table_out; // Provide test signal

endmodule