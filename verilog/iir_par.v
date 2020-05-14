//*********************************************************
// IEEE STD 1364-2001 Verilog file: iir_par.v
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module iir_par          //----> Interface
#(parameter W = 14) // bit width - 1
 (input  clk,                  // System clock
  input reset,                 // Asynchronous reset    
  input signed [W:0] x_in,     // System input
  output signed [W:0] x_e, x_o,// Even/odd input x_in
  output signed [W:0] y_e, y_o,// Even/odd output y_out
  output clk2,                 // Clock divided by 2
  output signed [W:0]  y_out); // System output
// --------------------------------------------------------
  reg signed [W:0] x_even, xd_even, x_odd, xd_odd, x_wait;
  reg signed [W:0] y_even, y_odd, y_wait, y;  
  reg signed [W:0] sum_x_even, sum_x_odd;
  reg        clk_div2;
  reg [0:0] state;
  
  always @(posedge clk or posedge reset) // Clock divider
  begin : clk_divider               // by 2 for input clk 
     if (reset) clk_div2 <= 0;
     else       clk_div2 <= ! clk_div2;
  end

  always @(posedge clk or posedge reset) // Split x into 
  begin : Multiplex              // even and odd samples; 
    parameter even=0, odd=1;     // recombine y at clk rate


    if (reset) begin                  // Asynchronous reset
      state <= even; x_even <= 0; x_odd <= 0;
       y <= 0; x_wait <= 0; y_wait <= 0;
    end else
      case (state) 
        even : begin
            x_even <= x_in; 
            x_odd <= x_wait;
            y <= y_wait;
            state <= odd;
        end
        odd : begin
           x_wait <= x_in;
           y <= y_odd;
           y_wait <= y_even;
           state <= even;
        end
      endcase
  end

  assign y_out = y;
  assign clk2  = clk_div2;
  assign x_e = x_even; // Monitor some extra test signals
  assign x_o = x_odd;
  assign y_e = y_even;
  assign y_o = y_odd;
  
  always @(negedge clk_div2 or posedge reset)
  begin: Arithmetic  
    if (reset) begin
      xd_even <= 0; sum_x_even <= 0; y_even<= 0; 
      xd_odd<= 0; sum_x_odd <= 0; y_odd <= 0; 
    end else begin
      xd_even <= x_even;                                    
      sum_x_even <= x_odd+ (xd_even >>> 1)+(xd_even >>> 2);
                     // i.e. x_odd + x_even/2 + x_even /4 
      y_even <= sum_x_even + (y_even >>> 1)+(y_even >>> 4);
               // i.e. sum_x_even + y_even / 2 + y_even /16
      xd_odd <= x_odd;
      sum_x_odd <= xd_even + (xd_odd >>> 1)+(xd_odd >>> 4);
                    // i.e. x_even + xd_odd / 2 + xd_odd /4
      y_odd  <= sum_x_odd + (y_odd >>> 1)+ (y_odd >>> 4);
                 // i.e. sum_x_odd + y_odd / 2 + y_odd / 16
    end
  end

endmodule
