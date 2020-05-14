//*********************************************************
// IEEE STD 1364-2001 Verilog file: sqrt.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
module sqrt                        //----> Interface
 (input  clk,                      // System clock
  input  reset,                    // Asynchronous reset
  output [1:0]  count_o,           // Counter SLL
  input  signed [16:0] x_in,       // System input
  output signed [16:0] pre_o,      // Prescaler
  output signed [16:0] x_o,        // Normalized x_in
  output signed [16:0] post_o,     // Postscaler
  output signed [3:0]  ind_o,      // Index to p
  output signed [16:0] imm_o,      // ALU preload value
  output signed [16:0] a_o,        // ALU factor 
  output signed [16:0] f_o,        // ALU output
  output reg signed [16:0] f_out); // System output
// --------------------------------------------------------   
  // Define the operation modes:
  parameter load=0, mac=1, scale=2, denorm=3, nop=4;
  //  Assign the FSM states:
  parameter start=0, leftshift=1, sop=2, 
                   rightshift=3, done=4;

  reg [3:0] s, op;
  reg [16:0] x; // Auxilary 
  reg signed [16:0] a, b, f, imm; // ALU data
  reg signed [33:0] af; // Product double width
  reg [16:0] pre, post;
  reg signed [3:0] ind;
  reg [1:0] count;
  // Chebychev poly coefficients for 16 bit precision:
  wire signed [16:0] p [0:4]; 
  
  assign p[0] = 7563;
  assign p[1] = 42299;
  assign p[2] = -29129;
  assign p[3] = 15813;
  assign p[4] = -3778;
  
  always @(posedge reset or posedge clk) //------> SQRT FSM
  begin : States                      // sample at clk rate

    if (reset) begin               // Asynchronous reset
      s <= start; f_out <= 0; op <= 0; count <= 0;
      imm <= 0; ind <= 0; a <= 0; x <= 0; 
    end else begin 
      case (s)                 // Next State assignments
        start : begin          // Initialization step 
          s <= leftshift; ind = 4;
          imm <= x_in;         // Load argument in ALU
          op <= load; count = 0;
        end
        leftshift : begin      // Normalize to 0.5 .. 1.0
          count = count + 1; a <= pre; op <= scale;
          imm <= p[4];
          if (count == 2) op <= nop;
          if (count == 3) begin // Normalize ready ?
            s <= sop; op <= load; x <= f; 
          end
        end
        sop :  begin            // Processing step
          ind = ind - 1; a <= x;
          if (ind == -1) begin  // SOP ready ?
            s <= rightshift; op <= denorm; a <= post;
          end else begin
            imm <= p[ind]; op <= mac;
          end
        end
        rightshift : begin // Denormalize to original range
          s <= done; op <= nop;
        end
        done :  begin          // Output of results
        f_out <= f;            // I/O store in register
        op <= nop;
        s <= start;            // start next cycle
        end                   
      endcase
    end
  end

  always @(posedge reset or posedge clk) 
  begin : ALU             // Define the ALU operations
    if (reset)            // Asynchronous clear
      f <= 0;
    else begin
      af = a * f;
      case (op)
        load    : f  <= imm;
        mac     : f  <= (af >>> 15) + imm;
        scale   : f  <= af;
        denorm  : f  <= af >>> 15;
        nop     : f  <= f;
        default : f  <= f;
      endcase
    end
  end

  always @(x_in)
  begin : EXP
    reg [16:0] slv;
    reg [16:0] po, pr;
    integer K; // Loop variable

    slv = x_in;
    // Compute pre-scaling:
    for (K=0; K <= 15; K= K+1) 
      if (slv[K] == 1)
    pre = 1 << (14-K);
    // Compute post scaling:
    po = 1;     
    for (K=0; K <= 7; K= K+1) begin
      if (slv[2*K] == 1)    // even 2^k gets 2^k/2
        po = 1 << (K+8);
//  sqrt(2): CSD Error = 0.0000208 = 15.55 effective bits
// +1 +0. -1 +0 -1 +0 +1 +0 +1 +0 +0 +0 +0 +0 +1
//  9      7     5     3     1               -5
      if (slv[2*K+1] == 1) // odd k has sqrt(2) factor
        po = (1<<(K+9)) - (1<<(K+7)) - (1<<(K+5))
              + (1<<(K+3)) + (1<<(K+1)) + (1<<(K-5));
    end
    post <= po;
  end

  assign a_o = a;   // Provide some test signals as outputs
  assign imm_o = imm;
  assign f_o = f;
  assign pre_o = pre;
  assign post_o = post;
  assign x_o = x;
  assign ind_o = ind;
  assign count_o = count;

endmodule
