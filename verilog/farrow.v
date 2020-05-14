//*********************************************************
// IEEE STD 1364-2001 Verilog file: farrow.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module farrow #(parameter IL = 3) // Input buffer length -1
  (input clk,                       // System clock
   input reset,                     // Asynchronous reset 
   input signed [7:0] x_in,         // System input
   output [3:0] count_o,            // Counter FSM
   output ena_in_o,                 // Sample input enable
   output ena_out_o,                // Shift output enable    
   output signed [8:0] c0_o,c1_o,c2_o,c3_o, // Phase delays
   output [8:0] d_out,                      // Delay used  
   output reg signed [8:0] y_out);         // System output        
// -------------------------------------------------------- 
  reg [3:0] count; // Cycle R_1*R_2
  wire [6:0] delta; // Increment d
  reg ena_in, ena_out; // FSM enables
  reg signed [7:0] x [0:3];
  reg signed [7:0] ibuf [0:3]; // TAP registers
  reg [8:0]  d; // Fractional Delay scaled to 8 bits
  // Lagrange matrix outputs: 
  reg signed [8:0] c0, c1, c2, c3;

  assign delta = 85;

  always @(posedge reset or posedge clk)     // Control the
  begin : FSM              // system and sample at clk rate
    reg [8:0] dnew;
    if (reset) begin             // Asynchronous reset
      count <= 0;
      d <= delta;
    end else begin 
      if (count == 11)  
        count <= 0;
      else
        count <= count + 1;
      if (ena_out) begin      // Compute phase delay 
       dnew = d + delta;
         if (dnew >= 255)
           d <= 0;
         else
           d <= dnew;
      end
    end
  end  
  
  always @(posedge clk or posedge reset) 
  begin         // Set the enable signals for the TAP lines
      case (count) 
        2, 5, 8, 11 : ena_in <= 1; 
        default     : ena_in <= 0;
      endcase
      
      case (count)
        3, 7, 11 : ena_out <= 1; 
        default  : ena_out <= 0;
      endcase
  end 

  always @(posedge clk or posedge reset)  
  begin : TAP                 //----> One tapped delay line
    integer I;    // loop variable 
    if (reset)          // Asynchronous clear
      for (I=0; I<=IL; I=I+1) ibuf[I] <= 0;
    else if (ena_in) begin
      for (I=1; I<=IL; I=I+1)      
        ibuf[I-1] <= ibuf[I];   // Shift one 
        
      ibuf[IL] <= x_in;         // Input in register IL
    end
  end
  
  always @(posedge clk or posedge reset)      
  begin : GET                  // Get 4 samples at one time
    integer I;    // loop variable 
    if (reset)          // Asynchronous clear
      for (I=0; I<=IL; I=I+1) x[I] <= 0;
    else if (ena_out) begin
      for (I=0; I<=IL; I=I+1)      
        x[I] <= ibuf[I];   // take over input buffer             
    end
  end

  // Compute sum-of-products:
  always @(posedge clk or posedge reset) 
  begin :  SOP
    reg signed [8:0] y1, y2, y3; // temp's  
  
// Matrix multiplier iV=inv(Vandermonde) c=iV*x(n-1:n+2)'
//      x(0)   x(1)         x(2)     x(3)
// iV=    0    1.0000         0         0
//   -0.3333   -0.5000    1.0000   -0.1667
//    0.5000   -1.0000    0.5000         0
//   -0.1667    0.5000   -0.5000    0.1667
    if (reset) begin          // Asynchronous clear
      y_out <= 0;
      c0 <= 0; c1 <= 0; c2<= 0; c3 <= 0;
    end else if (ena_out) begin
      c0 <= x[1];
      c1 <= (-85 * x[0] >>> 8) - (x[1]/2) + x[2] - 
                                         (43 * x[3] >>> 8);
      c2 <= ((x[0] + x[2]) >>> 1) - x[1] ;
      c3 <= ((x[1] - x[2]) >>> 1) + 
                                (43 * (x[3] - x[0]) >>> 8);
   
// Farrow structure = Lagrange with Horner schema
// for u=0:3, y=y+f(u)*d^u; end;
      y1 = c2 + ((c3 * d) >>> 8); // d is scale by 256
      y2 = ((y1 * d) >>> 8) + c1;
      y3 = ((y2 * d) >>> 8) + c0;
  
      y_out <= y3; // Connect to output + store in register
  end
end
  
  assign c0_o = c0; // Provide test signals as outputs
  assign c1_o = c1;
  assign c2_o = c2;
  assign c3_o = c3;
  assign count_o = count;
  assign ena_in_o = ena_in;
  assign ena_out_o = ena_out;
  assign d_out = d;

endmodule
