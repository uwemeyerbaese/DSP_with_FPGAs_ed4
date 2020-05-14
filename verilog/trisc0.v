//*********************************************************
// IEEE STD 1364-2001 Verilog file: trisc0.v 
// Author-EMAIL: Uwe.Meyer-Baese@ieee.org
//*********************************************************
// Title: T-RISC stack machine 
// Description: This is the top control path/FSM of the 
// T-RISC, with a single 3 phase clock cycle design
// It has a stack machine/0-address type instruction word
// The stack has only 4 words.
// --------------------------------------------------------  
module trisc0 #(parameter WA = 7,  // Address bit width -1
                          WD = 7)    // Data bit width -1 
 (input  clk,              // System clock
  input  reset,            // Asynchronous reset
  output jc_out,           // Jump condition flag
  output me_ena,           // Memory enable
  input [WD:0] iport,      // Input port
  output reg [WD:0] oport, // Output port
  output signed [WD:0] s0_out,    // Stack register 0
  output signed [WD:0] s1_out,    // Stack register 1
  output [WD:0] dmd_in,    // Data memory data read
  output [WD:0] dmd_out,   // Data memory data read
  output [WD:0] pc_out,    // Progamm counter
  output [WD:0] dma_out,   // Data memory address write
  output [WD:0] dma_in,    // Data memory address read
  output [7:0]  ir_imm,    // Immidiate value 
  output [3:0]  op_code);  // Operation code
// --------------------------------------------------------
  //parameter ifetch=0, load=1, store=2, incpc=3;
  reg [1:0] state;
  
  wire [3:0] op;   
  wire [WD:0] imm, dmd;
  reg signed [WD:0] s0, s1, s2, s3;
  reg [WA:0] pc;
  wire [WA:0] dma;
  wire [11:0] pmd, ir;
  wire eq, ne, not_clk;
  reg mem_ena, jc;

// OP Code of instructions:
  parameter 
  add  = 0,  neg   = 1, sub  = 2, opand = 3, opor = 4, 
  inv  = 5,  mul   = 6, pop  = 7, pushi = 8, push = 9, 
  scan = 10, print = 11, cne = 12, ceq  = 13, cjp = 14,
  jmp  = 15;

  always @(*) // sequential FSM of processor
              // Check store in register ? 
      case (op)  // always store except Branch
        pop     : mem_ena <= 1;
        default : mem_ena <= 0;
      endcase
      
  always @(negedge clk or posedge reset)    
      if (reset == 1)  // update the program counter
        pc <= 0;
      else begin    // use falling edge
        if (((op==cjp) & (jc==0)) | (op==jmp)) 
          pc <= imm;
        else 
          pc <= pc + 1; 
      end

  always @(posedge clk or posedge reset) 
    if (reset)         // compute jump flag and store in FF
      jc <= 0;
    else
      jc <= ((op == ceq) & (s0 == s1)) | 
                                ((op == cne) & (s0 != s1));

  // Mapping of the instruction, i.e., decode instruction
  assign op  = ir[11:8];   // Operation code
  assign dma = ir[7:0];    // Data memory address
  assign imm = ir[7:0];    // Immidiate operand

  prog_rom brom
  ( .clk(clk), .reset(reset), .address(pc), .q(pmd));  
  assign ir = pmd;
 
  assign not_clk = ~clk;

  data_ram bram
  ( .clk(not_clk),.address(dma), .q(dmd), 
    .data(s0), .we(mem_ena));  
  
  always @(posedge clk or posedge reset)
  begin : P3
    integer temp;
    if (reset) begin       // Asynchronous clear
      s0 <= 0; s1 <= 0; s2 <= 0; s3 <= 0;
      oport <= 0;
    end else begin 
      case (op) 
        add    :   s0  <= s0 + s1;
        neg    :   s0  <= -s0;
        sub    :   s0  <= s1 - s0;
        opand  :   s0  <= s0 & s1;
        opor   :   s0  <= s0 | s1;
        inv    :   s0  <= ~ s0; 
        mul    :   begin temp  = s0 * s1;  // double width
                   s0  <= temp[WD:0]; end  // product
        pop    :   s0  <= s1;
        push   :   s0  <= dmd;
        pushi  :   s0  <= imm;
        scan   :   s0 <= iport;
        print  :   begin oport <= s0; s0<=s1; end
        default:   s0 <= 0;
      endcase
      case (op) // Specify the stack operations
        pushi, push, scan : begin s3<=s2; 
                s2<=s1; s1<=s0; end            // Push type
        cjp, jmp,  inv | neg : ;   // Do nothing for branch
        default :  begin s1<=s2; s2<=s3; s3<=0; end 
                                          // Pop all others
      endcase
    end
  end

  // Extra test pins:
  assign dmd_out = dmd; assign dma_out = dma; //Data memory 
  assign dma_in = dma; assign dmd_in  = s0;
  assign pc_out = pc;  assign ir_imm = imm; 
  assign op_code = op;  // Program control
  // Control signals:
  assign jc_out = jc; assign me_ena = mem_ena; 
  // Two top stack elements:
  assign s0_out = s0; assign s1_out = s1; 

endmodule
