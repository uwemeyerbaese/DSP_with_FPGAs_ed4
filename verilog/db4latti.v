//*********************************************************
// IEEE STD 1364-2001 Verilog file: db4latti.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module db4latti
 (input clk,                      // System clock
  input reset,                    // Asynchron reset
  output clk2,                    // Clock divider
  input signed  [7:0]  x_in,      // System input
  output signed [16:0]  x_e, x_o, // Even/odd x input
  output reg signed [8:0]   g, h);// g/h filter output
// --------------------------------------------------------
  reg signed  [7:0]  x_wait;
  reg signed  [16:0] sx_up, sx_low;
  reg  clk_div2;
  wire signed [16:0] sxa0_up, sxa0_low;
  wire signed [16:0] up0, up1, low1;
  reg signed  [16:0] low0;

  always @(posedge clk or posedge reset) // Split into even
  begin : Multiplex          // and odd samples at clk rate 
    parameter even=0, odd=1;
    reg [0:0] state;

    if (reset) begin             // Asynchronous reset
      state <= even;
      sx_up <= 0; sx_low <= 0; 
      clk_div2 <= 0; x_wait <= 0;
    end else
      case (state) 
        even : begin
          // Multiply with 256*s=124
          sx_up   <= (x_in <<< 7) - (x_in <<< 2);
          sx_low  <= (x_wait <<< 7) - (x_wait <<< 2);
          clk_div2 <= 1;
          state <= odd;
        end
        odd : begin
          x_wait <= x_in;
          clk_div2 <= 0;
          state <= even;
        end
      endcase  
  end
  
//******** Multipy a[0] = 1.7321
// Compute: (2*sx_up  - sx_up /4)-(sx_up /64 + sx_up /256)
  assign sxa0_up  = ((sx_up <<< 1)  - (sx_up >>> 2))
                  - ((sx_up >>> 6) + (sx_up >>> 8)); 
// Compute: (2*sx_low - sx_low/4)-(sx_low/64 + sx_low/256)
  assign sxa0_low = ((sx_low <<< 1) - (sx_low >>> 2))
                 - ((sx_low >>> 6) + (sx_low >>> 8));

//******** First stage -- FF in lower tree
  assign up0 = sxa0_low + sx_up;
  always @(posedge clk or posedge reset)
  begin: LowerTreeFF
    if (reset) begin             // Asynchronous clear
      low0 <= 0; 
    end else if (clk_div2)
      low0 <= sx_low - sxa0_up;         
  end

//******** Second stage: a[1]=-0.2679
// Compute:   (up0 - low0/4) - (low0/64 + low0/256);
  assign up1  = (up0 - (low0 >>> 2)) 
                 - ((low0 >>> 6) + (low0 >>> 8));
// Compute: (low0 + up0/4) + (up0/64  +  up0/256)
  assign low1 = (low0 + (up0 >>> 2)) 
                       + ((up0 >>> 6) + (up0 >>> 8));

  assign x_e  = sx_up;       // Provide some extra 
  assign x_o  = sx_low;      // test signals 
  assign clk2 = clk_div2;

  always @(posedge clk or posedge reset)
  begin: OutputScale
    if (reset) begin             // Asynchronous clear
      g <= 0; h <= 0; 
    end else if (clk_div2) begin
      g <= up1 >>> 8;      // i.e. up1 / 256
      h <= low1 >>> 8;     // i.e. low1 / 256;
    end
  end

endmodule