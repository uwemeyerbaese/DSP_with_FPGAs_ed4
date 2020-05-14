//*********************************************************
// IEEE STD 1364-2001 Verilog file: mul_ser.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module mul_ser      //----> Interface
 (input         clk, reset,
  input  signed [7:0]  x,
  input   [7:0]  a,
  output reg signed [15:0] y);

  always @(posedge clk) //-> Multiplier in behavioral style
  begin : States
    parameter s0=0, s1=1, s2=2;
    reg [2:0] count;
    reg [1:0] s;                   // FSM state register
    reg signed [15:0] p, t;        // Double bit width
    reg  [7:0] a_reg;

    if (reset)              // Asynchronous reset
      s <= s0;
    else
      case (s) 
        s0 : begin         // Initialization step 
          a_reg <= a;
          s <= s1;
          count = 0;
          p <= 0;      // Product register reset
          t <= x;      // Set temporary shift register to x
        end
        s1 : begin          // Processing step
          if (count == 7)   // Multiplication ready
            s <= s2;
          else          
            begin      
            if (a_reg[0] == 1) // Use LSB for bit select
              p <= p + t;      // Add 2^k
            a_reg <= a_reg >>> 1;
            t <= t <<< 1;
            count = count + 1;
            s <= s1;
          end
        end
        s2 : begin       // Output of result to y and
          y <= p;        // start next multiplication
          s <= s0;
        end
      endcase  
  end

endmodule