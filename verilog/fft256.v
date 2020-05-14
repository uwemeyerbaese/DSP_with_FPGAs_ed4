//*********************************************************
// IEEE STD 1364-2001 Verilog file: fft256.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module fft256             //----> Interface
 (input  clk,             // System clock
  input  reset,           // Asynchronous reset
  input signed [15:0] xr_in, xi_in, // Real and imag. input
  output reg fft_valid, // FFT output is valid
  output reg signed [15:0] fftr, ffti, // Real/imag. output
  output [8:0] rcount_o, // Bitreverese index counter 
  output [15:0] xr_out0, // Real first in reg. file
  output [15:0] xi_out0, // Imag. first in reg. file
  output [15:0] xr_out1, // Real second in reg. file
  output [15:0] xi_out1, // Imag. second in reg. file
  output [15:0] xr_out255, // Real last in reg. file
  output [15:0] xi_out255, // Imag. last in reg. file
  output [8:0] stage_o, gcount_o, // Stage and group count
  output [8:0] i1_o, i2_o, // (Dual) data index 
  output [8:0] k1_o, k2_o, // Index offset 
  output [8:0] w_o, dw_o, // Cos/Sin (increment) angle 
  output reg [8:0] wo);  // Decision tree location loop FSM
// --------------------------------------------------------
  reg[2:0] s; // State machine variable
  parameter start=0, load=1, calc=2, update=3, 
                                         reverse=4, done=5;

  reg [8:0] w;
  reg signed [15:0] sin, cos; 
  reg signed [15:0] tr, ti;
  // Double length product
  reg signed [31:0] cos_tr, sin_ti, cos_ti, sin_tr;        
  reg [15:0] cos_rom[127:0];
  reg [15:0] sin_rom[127:0];
  reg [8:0] i1, i2, gcount, k1, k2;
  reg [8:0] stage, dw; 
  reg [7:0] rcount;

  reg [7:0] slv, rslv;
  wire [8:0] N, ldN;
  assign N = 256; // Number of points
  assign ldN = 8; // Log_2 number of points
  // Register array for 16 bit precision: 
  reg [15:0] xr[255:0];
  reg [15:0] xi[255:0];         
    
  initial
  begin
    $readmemh("cos128x16.txt", cos_rom);
    $readmemh("sin128x16.txt", sin_rom);
  end

  always @ (negedge clk or posedge reset)
    if (reset == 1)  begin
      cos <= 0; sin <= 0;
    end else begin
      cos <= cos_rom[w[6:0]];
      sin <= sin_rom[w[6:0]];  
    end

  always @(posedge reset or posedge clk)
  begin : States                 // FFT in behavioral style
    integer k;
    reg [8:0] count;
    if (reset) begin             // Asynchronous reset
      s <= start; count = 0;
        gcount = 0; stage= 1; i1 = 0; i2 = N/2; k1=N; 
        k2=N/2; dw = 1; fft_valid <= 0;
        fftr <= 0; ffti <= 0; wo <= 0;
    end else
      case (s)                  // Next State assignments
      start : begin
        s <= load; count <= 0; w <= 0;
        gcount = 0; stage= 1; i1 = 0; i2 = N/2; k1=N; 
        k2=N/2; dw = 1; fft_valid <= 0; rcount <= 0;
      end
      load : begin       // Read in all data from I/O ports
        xr[count] <= xr_in; xi[count] <= xi_in;
        count <= count + 1;
        if (count == N)  s <= calc;
        else             s <= load;
       end
       calc : begin         // Do the butterfly computation
         tr = xr[i1] - xr[i2];
         xr[i1] <= xr[i1] + xr[i2];
         ti = xi[i1] - xi[i2];
         xi[i1] <= xi[i1] + xi[i2];  
         cos_tr = cos * tr; sin_ti = sin * ti;
         xr[i2] <= (cos_tr >>> 14) + (sin_ti >>> 14);
         cos_ti = cos * ti; sin_tr = sin * tr;
         xi[i2] <= (cos_ti >>> 14) - (sin_tr >>> 14);
         s <= update;
       end
       update : begin          // all counters and pointers
         s  <= calc;        // by default do next butterfly
         i1 = i1 + k1;      // next butterfly in group 
         i2 = i1 + k2; 
         wo <= 1;
         if ( i1 >= N-1 ) begin  // all butterfly 
           gcount = gcount + 1;  // done in group?
           i1 = gcount;
           i2 = i1 + k2;
           wo <= 2;
           if ( gcount >= k2 ) begin     // all groups done
             gcount = 0; i1 = 0; i2 = k2; // in stages?
             dw = dw * 2;
             stage  = stage + 1;
             wo <= 3;
             if (stage > ldN) begin // all stages done
               s <= reverse;
               count = 0;
               wo <= 4;
             end else begin // start new stage
               k1 = k2; k2 = k2/2;
               i1 = 0; i2 = k2;
               w  <= 0;
               wo <= 5;
             end
           end else begin // start new group
             i1 = gcount;  i2 = i1 + k2;
             w <= w + dw;
             wo <= 6;
           end
         end
       end
       reverse : begin   // Apply Bit Reverse
         fft_valid <= 1;
         for (k=0;k<=7;k=k+1) rcount[k] = count[7-k];
         fftr <= xr[rcount]; ffti <= xi[rcount];
         count = count + 1;
         if (count >= N)  s <= done;
         else             s <= reverse;
       end
       done : begin      // Output of results
         s <= start;     // start next cycle
       end
     endcase
   end  
   
  assign xr_out0 = xr[0];
  assign xi_out0 = xi[0];
  assign xr_out1 = xr[1];
  assign xi_out1 = xi[1];
  assign xr_out255 = xr[255];
  assign xi_out255 = xi[255];  
  assign i1_o = i1; // Provide some test signals as outputs
  assign i2_o = i2;   
  assign stage_o = stage;
  assign gcount_o = gcount;
  assign k1_o = k1;
  assign k2_o = k2;
  assign w_o = w;
  assign dw_o = dw;
  assign rcount_o = rcount;
  assign w_out = w;
  assign cos_out = cos;
  assign sin_out = sin;
  
endmodule
