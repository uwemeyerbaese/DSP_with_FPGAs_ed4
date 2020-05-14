//*********************************************************
// IEEE STD 1364-2001 Verilog file: div_res.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// Restoring Division
// Bit width:  WN         WD           WN            WD
//         Nominator / Denumerator = Quotient and Remainder
// OR:       Nominator = Quotient * Denumerator + Remainder
// --------------------------------------------------------
module div_res               //------> Interface
  (input clk,                // System clock
   input reset,              // Asynchron reset
   input  [7:0] n_in,        // Nominator
   input  [5:0] d_in,        // Denumerator
   output reg [5:0] r_out,   // Remainder
   output reg [7:0] q_out);  // Quotient
// --------------------------------------------------------
  reg [1:0] state;           // FSM state 
  parameter ini=0, sub=1, restore=2, done=3; // State
                                             // assignments
  // Divider in behavioral style
  always @(posedge clk or posedge reset) 
  begin : States // Finite state machine 
    reg [3:0] count;

    reg  [13:0] d;        // Double bit width unsigned
    reg  signed [13:0] r; // Double bit width signed
    reg  [7:0] q;

    if (reset) begin              // Asynchronous reset
      state <= ini; count <= 0; 
      q <= 0; r <= 0; d <= 0; q_out <= 0; r_out <= 0;
    end else
      case (state) 
        ini : begin         // Initialization step 
          state <= sub;
          count = 0;
          q <= 0;           // Reset quotient register
          d <= d_in << 7;   // Load aligned denumerator
          r <= n_in;        // Remainder = nominator
        end                                           
        sub : begin         // Processing step 
          r <= r - d;      // Subtract denumerator
          state <= restore;
        end
        restore : begin          // Restoring step
          if (r < 0) begin  // Check r < 0 
            r <= r + d;     // Restore previous remainder
            q <= q << 1;     // LSB = 0 and SLL
            end
          else
            q <= (q << 1) + 1; // LSB = 1 and SLL
          count = count + 1;
          d <= d >> 1;

          if (count == 8)   // Division ready ?
            state <= done;
          else             
            state <= sub;
        end
        done : begin       // Output of result
          q_out <= q[7:0]; 
          r_out <= r[5:0]; 
          state <= ini;   // Start next division
        end
      endcase  
  end

endmodule