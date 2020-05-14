//*********************************************************
// IEEE STD 1364-2001 Verilog file: ammod.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module ammod #(parameter W = 8)  // Bit width - 1
 (input        clk,              // System clock
  input        reset,            // Asynchronous reset
  input signed [W:0] r_in,       // Radius input 
  input signed [W:0] phi_in,     // Phase input
  output reg signed [W:0] x_out, // x or real part output
  output reg signed [W:0] y_out, // y or imaginary part
  output reg signed [W:0] eps);  // Error of results
// --------------------------------------------------------
  reg signed [W:0] x [0:3]; // There is bit access in 2D 
  reg signed [W:0] y [0:3]; // array types in  
  reg signed [W:0] z [0:3]; // Quartus Verilog 2001

  always @(posedge clk or posedge reset)
  begin: Pipeline
    integer k;    // Loop variable    
    if (reset) begin                             
      for (k=0; k<=3; k=k+1) begin    // Asynchronous clear
        x[k] <= 0; y[k] <= 0; z[k] <= 0;  
      end
        x_out <= 0; eps <= 0; y_out <= 0;
      end
    else begin
    
      if (phi_in > 90) begin  // Test for |phi_in| > 90
        x[0] <= 0;            // Rotate 90 degrees 
        y[0] <= r_in;         // Input in register 0
        z[0] <= phi_in - 'sd90;
      end else if (phi_in < - 90) begin
                 x[0] <= 0;
                 y[0] <= - r_in;
                 z[0] <= phi_in + 'sd90;
               end else begin
                  x[0] <= r_in;
                  y[0] <= 0;
                  z[0] <= phi_in;
               end

      if (z[0] >= 0)  begin           // Rotate 45 degrees
          x[1] <= x[0] - y[0];
          y[1] <= y[0] + x[0];
          z[1] <= z[0] - 'sd45;
      end else begin
          x[1] <= x[0] + y[0];
          y[1] <= y[0] - x[0];
          z[1] <= z[0] + 'sd45;
      end

      if (z[1] >= 0)  begin       // Rotate 26 degrees
        x[2] <= x[1] - (y[1] >>> 1); // i.e. x[1] - y[1] /2
        y[2] <= y[1] + (x[1] >>> 1); // i.e. y[1] + x[1] /2
        z[2] <= z[1] - 'sd26;
      end else begin
        x[2] <= x[1] + (y[1] >>> 1); // i.e. x[1] + y[1] /2
        y[2] <= y[1] - (x[1] >>> 1); // i.e. y[1] - x[1] /2
        z[2] <= z[1] + 'sd26;
      end

      if (z[2] >= 0)  begin         // Rotate 14 degrees
        x[3] <= x[2] - (y[2] >>> 2); // i.e. x[2] - y[2]/4
        y[3] <= y[2] + (x[2] >>> 2); // i.e. y[2] + x[2]/4
        z[3] <= z[2] - 'sd14;
      end else begin
        x[3] <= x[2] + (y[2] >>> 2); // i.e. x[2] + y[2]/4
        y[3] <= y[2] - (x[2] >>> 2); // i.e. y[2] - x[2]/4
        z[3] <= z[2] + 'sd14;
      end

      x_out <= x[3];
      eps   <= z[3];
      y_out <= y[3];
    end
  end

endmodule
