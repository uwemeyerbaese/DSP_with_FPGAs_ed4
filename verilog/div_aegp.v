//*********************************************************
// IEEE STD 1364-2001 Verilog file: div_aegp.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// Convergence division after 
//                 Anderson, Earle, Goldschmidt, and Powers
// Bit width:  WN         WD           WN            WD
//         Nominator / Denumerator = Quotient and Remainder
// OR:       Nominator = Quotient * Denumerator + Remainder
// --------------------------------------------------------
module div_aegp
  (input clk,                // System clock
   input reset,              // Asynchron reset
   input  [8:0] n_in,        // Nominator
   input  [8:0] d_in,        // Denumerator 
   output reg [8:0] q_out);  // Quotient
// --------------------------------------------------------
  reg [1:0] state;
  always @(posedge clk or posedge reset) //-> Divider in 
  begin : States                        // behavioral style
    parameter s0=0, s1=1, s2=2;
    reg [1:0] count;

    reg [9:0] x, t, f;        // one guard bit 
    reg [17:0] tempx, tempt;

    if (reset) begin              // Asynchronous reset
      state <= s0; q_out <= 0; count = 0; x <= 0; t <= 0;
    end else
      case (state) 
        s0 : begin              // Initialization step
          state <= s1;
          count = 0;
          t <= {1'b0, d_in};    // Load denumerator
          x <= {1'b0, n_in};    // Load nominator
        end                                           
        s1 : begin            // Processing step 
          f = 512 - t;        // TWO - t
          tempx = (x * f);  // Product in full
          tempt = (t * f);  // bitwidth
          x <= tempx >> 8;  // Factional f
          t <= tempt >> 8;  // Scale by 256
          count = count + 1;
          if (count == 2)     // Division ready ?
            state <= s2;
          else             
            state <= s1;
        end
        s2 : begin       // Output of result
          q_out <= x[8:0]; 
          state <= s0;   // Start next division
        end
      endcase  
  end

endmodule