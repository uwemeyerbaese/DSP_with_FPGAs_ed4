//*********************************************************
// IEEE STD 1364-2001 Verilog file: rader7.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module rader7                     //---> Interface
 (input  clk,                     // System clock
  input reset,                    // Asynchronous reset    
  input  [7:0]  x_in,             // Real system input
  output reg signed[10:0] y_real, //Real system output
  output reg signed[10:0] y_imag);//Imaginary system output
// -------------------------------------------------------- 
  reg signed [10:0]  accu;               // Signal for X[0]
 // Direct bit access of 2D vector in Quartus Verilog 2001
 // works; no auxiliary signal for this purpose necessary
  reg signed [18:0] im [0:5]; 
  reg signed [18:0] re [0:5];  
 // real is keyword in Verilog and can not be an identifier
                                 // Tapped delay line array
  reg signed [18:0]  x57, x111, x160, x200, x231, x250 ; 
                                 // The filter coefficients
  reg signed [18:0]  x5, x25, x110, x125, x256; 
                           // Auxiliary filter coefficients
  reg signed [7:0]   x, x_0;            // Signals for x[0]
  reg [1:0] state; // State variable
  reg [4:0] count; // Clock cycle counter
    
  always @(posedge clk or posedge reset)   // State machine
  begin : States                        // for RADER filter
    parameter Start=0, Load=1, Run=2;

    if (reset) begin              // Asynchronous reset
      state <= Start; accu <= 0;
      count <= 0; y_real <= 0; y_imag <= 0;       
    end else
      case (state) 
        Start : begin        // Initialization step 
          state <= Load;
          count <= 1;
          x_0 <= x_in;       // Save x[0]
          accu <= 0 ;        // Reset accumulator for X[0]
          y_real  <= 0;
          y_imag  <= 0;
        end
        Load : begin // Apply x[5],x[4],x[6],x[2],x[3],x[1]
          if (count == 8)     // Load phase done ?
            state <= Run;
          else begin
            state <= Load;
            accu <= accu + x;
          end
          count <= count + 1;
        end
        Run : begin // Apply again x[5],x[4],x[6],x[2],x[3]
          if (count == 15) begin // Run phase done ?
            y_real  <= accu;       // X[0]
            y_imag  <= 0;  // Only re inputs => Im(X[0])=0
            count <= 0;        // Output of result 
            state <= Start;    // and start again
          end else begin
            y_real  <= (re[0] >>> 8) + x_0; 
                                  // i.e. re[0]/256+x[0]
            y_imag  <= (im[0] >>> 8);     // i.e. im[0]/256
            state <= Run;
            count <= count + 1;
          end
        end
      endcase  
  end
// -------------------------------------------------------- 
  always @(posedge clk or posedge reset) // Structure of the 
  begin : Structure                     // two FIR filters 
    integer k;    // loop variable  
    if (reset) begin                  // in transposed form
      for (k=0; k<=5; k=k+1) begin
        re[k] <= 0; im[k] <= 0;   // Asynchronous clear
      end
      x <= 0;
    end else begin
      x <= x_in;
    // Real part of FIR filter in transposed form
      re[0] <= re[1] + x160  ;   // W^1
      re[1] <= re[2] - x231  ;   // W^3
      re[2] <= re[3] - x57   ;   // W^2
      re[3] <= re[4] + x160  ;   // W^6
      re[4] <= re[5] - x231  ;   // W^4
      re[5] <= -x57;             // W^5
    
    // Imaginary part of FIR filter in transposed form
      im[0] <= im[1] - x200  ;   // W^1
      im[1] <= im[2] - x111  ;   // W^3
      im[2] <= im[3] - x250  ;   // W^2
      im[3] <= im[4] + x200  ;   // W^6
      im[4] <= im[5] + x111  ;   // W^4
      im[5] <= x250;             // W^5
    end
  end
// -------------------------------------------------------- 
  always @(posedge clk or posedge reset) //  Note that all 
  begin : Coeffs            // signals are globally defined
  // Compute the filter coefficients and use FFs
    if (reset) begin       // Asynchronous clear
      x160 <= 0; x200 <= 0; x250 <= 0;
      x57 <= 0; x111 <= 0; x231 <= 0;
    end else begin
      x160 <= x5 <<< 5;        // i.e. 160 = 5 * 32;
      x200 <= x25 <<< 3;       // i.e. 200 = 25 * 8;
      x250 <= x125 <<< 1;      // i.e. 250 = 125 * 2;
      x57  <= x25 + (x <<< 5); // i.e. 57 = 25 + 32;
      x111 <= x110 + x;       // i.e. 111 = 110 + 1;
      x231 <= x256 - x25;     // i.e. 231 = 256 - 25;
    end
  end

  always @*                 // Note that all signals
  begin : Factors           // are globally defined 
  // Compute the auxiliary factor for RAG without an FF
    x5   = (x <<< 2) + x;  // i.e. 5 = 4 + 1;
    x25  = (x5 <<< 2) + x5;        // i.e. 25 = 5*4 + 5;
    x110 = (x25 <<< 2) + (x5 <<< 2);// i.e. 110 = 25*4+5*4;
    x125 = (x25 <<< 2) + x25;      // i.e. 125 = 25*4+25;
    x256 = x <<< 8;            // i.e. 256 = 2 ** 8;  
  end

endmodule
