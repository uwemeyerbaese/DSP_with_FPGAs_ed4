-- This is a generic FIR filter generator 
-- It uses W1 bit data/coefficients bits
LIBRARY ieee;                -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY fir_gen IS                      ------> Interface
  GENERIC (W1 : INTEGER := 9; -- Input bit width
           W2 : INTEGER := 18;-- Multiplier bit width 2*W1
           W3 : INTEGER := 19;-- Adder width = W2+log2(L)-1
           W4 : INTEGER := 11;-- Output bit width
           L  : INTEGER := 4  -- Filter length 
           );
  PORT ( clk    : IN STD_LOGIC;     -- System clock
         reset  : IN STD_LOGIC;     -- Asynchron reset
         Load_x : IN  STD_LOGIC;    -- Load/run switch
         x_in   : IN  STD_LOGIC_VECTOR(W1-1 DOWNTO 0);
                                  -- System input
         c_in   : IN  STD_LOGIC_VECTOR(W1-1 DOWNTO 0);
                                  -- Coefficient data input 
         y_out  : OUT STD_LOGIC_VECTOR(W4-1 DOWNTO 0));
END fir_gen;                      -- System output
-- --------------------------------------------------------
ARCHITECTURE fpga OF fir_gen IS

  SUBTYPE SLVW1 IS STD_LOGIC_VECTOR(W1-1 DOWNTO 0);
  SUBTYPE SLVW2 IS STD_LOGIC_VECTOR(W2-1 DOWNTO 0);
  SUBTYPE SLVW3 IS STD_LOGIC_VECTOR(W3-1 DOWNTO 0);
  TYPE A0_L1SLVW1 IS ARRAY (0 TO L-1) OF SLVW1;
  TYPE A0_L1SLVW2 IS ARRAY (0 TO L-1) OF SLVW2;
  TYPE A0_L1SLVW3 IS ARRAY (0 TO L-1) OF SLVW3;

  SIGNAL  x  :  SLVW1;
  SIGNAL  y  :  SLVW3;
  SIGNAL  c  :  A0_L1SLVW1 ; -- Coefficient array 
  SIGNAL  p  :  A0_L1SLVW2 ; -- Product array 
  SIGNAL  a  :  A0_L1SLVW3 ; -- Adder array 
                                                        
BEGIN

  Load: PROCESS(clk, reset, c_in, c, x_in)            
  BEGIN                   ------> Load data or coefficients
    IF reset = '1' THEN -- clear data and coefficients reg.
      x <= (OTHERS => '0');
      FOR K IN 0 TO L-1 LOOP
        c(K) <= (OTHERS => '0');
      END LOOP; 
    ELSIF rising_edge(clk) THEN  
    IF Load_x = '0' THEN
      c(L-1) <= c_in;      -- Store coefficient in register
      FOR I IN L-2 DOWNTO 0 LOOP  -- Coefficients shift one
        c(I) <= c(I+1);
      END LOOP;
    ELSE
      x <= x_in;           -- Get one data sample at a time
    END IF;
    END IF;
  END PROCESS Load;


  SOP: PROCESS (clk, reset, a, p)-- Compute sum-of-products
  BEGIN
    IF reset = '1' THEN -- clear tap registers
      FOR K IN 0 TO L-1 LOOP
        a(K) <= (OTHERS => '0');
      END LOOP; 
    ELSIF rising_edge(clk) THEN
    FOR I IN 0 TO L-2  LOOP      -- Compute the transposed
      a(I) <= (p(I)(W2-1) & p(I)) + a(I+1); -- filter adds
    END LOOP;
    a(L-1) <= p(L-1)(W2-1) & p(L-1);     -- First TAP has 
    END IF;                              -- only a register
    y <= a(0);
  END PROCESS SOP;

  -- Instantiate L multipliers 
  MulGen: FOR I IN 0 TO L-1 GENERATE  
    p(i) <= c(i) * x;
  END GENERATE;

  y_out <= y(W3-1 DOWNTO W3-W4);  

END fpga;

