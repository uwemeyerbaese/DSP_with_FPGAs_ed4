//*********************************************************
// IEEE STD 1364-2001 Verilog file: cmoms.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module cmoms #(parameter IL = 3)  // Input buffer length -1
  (input clk,                 // System clock
   input reset,               // Asynchron reset
   output [3:0] count_o, // Counter FSM         
   output ena_in_o,      // Sample input enable
   output ena_out_o,     // Shift output enable 
   input signed [7:0] x_in, // System input 
   output signed [8:0] xiir_o,     // IIR filter output           
   output signed [8:0] c0_o,c1_o,c2_o,c3_o,// C-MOMS matrix
   output signed [8:0] y_out);  // System output
// --------------------------------------------------------
  reg [3:0] count; // Cycle R_1*R_2
  reg [1:0] t;
  reg ena_in, ena_out; // FSM enables
  reg signed [7:0] x [0:3];
  reg signed [7:0] ibuf [0:3]; // TAP registers
  reg signed [8:0] xiir; // iir filter output
  
  reg signed [16:0] y, y0, y1, y2, y3, h0, h1; // temp's

  // Spline matrix output: 
  reg signed [8:0] c0, c1, c2, c3;

  // Precomputed value for d**k :
  wire signed [8:0] d1 [0:2];
  wire signed [8:0] d2 [0:2];
  wire signed [8:0] d3 [0:2];

  assign d1[0] = 0; assign d1[1] = 85; assign d1[2] = 171;
  assign d2[0] = 0; assign d2[1] = 28; assign d2[2] = 114;
  assign d3[0] = 0; assign d3[1] =  9; assign d3[2] =  76;
  
  
  always @(posedge reset or posedge clk) // Control the
  begin : FSM                  // system sample at clk rate
    if (reset) begin             // Asynchronous reset
      count <= 0;
      t <= 1;
    end else begin 
      if (count == 11)  
        count <= 0;
      else
        count <= count + 1;
      if (ena_out)
        if (t>=2)    // Compute phase delay 
          t <= 0;
        else
          t <= t + 1;
    end
  end  
  assign t_out = t;

  always @(posedge clk) // set the enable signal 
  begin                 // for the TAP lines
      case (count) 
        2, 5, 8, 11 : ena_in <= 1; 
        default     : ena_in <= 0;
      endcase
      
      case (count)
        3, 7, 11    : ena_out <= 1; 
        default : ena_out <= 0;
      endcase
  end  

//  Coeffs: H(z)=1.5/(1+0.5z^-1)
  always @(posedge clk or posedge reset)
  begin : IIR  // Compute iir coefficients first
    reg signed [8:0] x1;    // x * 1
    if (reset) begin  // Asynchronous clear
      xiir <= 0; x1 <= 0;
    end else    
    if (ena_in) begin    
      xiir <= (3 * x1 >>> 1) - (xiir >>> 1);
      x1 = x_in;         
    end
  end
    
  always @(posedge clk or posedge reset)
  begin : TAP                 //----> One tapped delay line
    integer I;    // Loop variable 
    if (reset) begin  // Asynchronous clear
      for (I=0; I<=IL; I=I+1) ibuf[I] <= 0;
    end else    
    if (ena_in) begin
      for (I=1; I<=IL; I=I+1)      
        ibuf[I-1] <= ibuf[I];   // Shift one 
                
        ibuf[IL] <= xiir;         // Input in register IL
    end
  end
  
  always @(posedge clk or posedge reset)
  begin : GET                  // Get 4 samples at one time
    integer I;    // Loop variable 
    if (reset) begin  // Asynchronous clear
    for (I=0; I<=IL; I=I+1) x[I] <= 0;             
    end else     
      if (ena_out) begin
      for (I=0; I<=IL; I=I+1)      
        x[I] <= ibuf[I];   // Take over input buffer
      end
  end

  // Compute sum-of-products:
  always @(posedge clk or posedge reset)
  begin :  SOP
// Matrix multiplier C-MOMS matrix: 
//    x(0)      x(1)      x(2)      x(3)
//    0.3333    0.6667    0          0
//   -0.8333    0.6667    0.1667     0
//    0.6667   -1.5       1.0       -0.1667
//   -0.1667    0.5      -0.5        0.1667
    if (reset) begin  // Asynchronous clear
      c0 <= 0; c1 <= 0; c2 <= 0; c3 <= 0;  
      y0 <= 0; y1 <= 0; y2 <= 0; y3 <= 0; 
      h0 <= 0; h1 <= 0; y <= 0;            
    end else if (ena_out) begin
      c0 <= (85 * x[0] + 171 * x[1]) >>> 8;
      c1 <= (171 * x[1] - 213 * x[0] + 43 * x[2]) >>> 8;
      c2 <= (171 * x[0] - (43 * x[3]) >>> 8)
                                 - (3 * x[1] >>> 1) + x[2];
      c3 <= (43 * (x[3] - x[0]) >>> 8) 
                                  +  ((x[1] - x[2]) >>> 1);
     
// No Farrow structure, parallel LUT for delays
// for u=0:3, y=y+f(u)*d^u; end;
      y0 <= c0 * 256; // Use pipelined adder tree
      y1 <= c1 * d1[t];
      y2 <= c2 * d2[t];
      y3 <= c3 * d3[t];
      h0 <= y0 + y1;
      h1 <= y2 + y3;
      y  <= h0 + h1;
    end
  end
  
  assign y_out = y >>> 8; // Connect to output
  assign c0_o = c0; // Provide some test signals as outputs
  assign c1_o = c1;
  assign c2_o = c2;
  assign c3_o = c3;
  assign count_o = count;
  assign ena_in_o = ena_in;
  assign ena_out_o = ena_out;
  assign xiir_o = xiir;

endmodule