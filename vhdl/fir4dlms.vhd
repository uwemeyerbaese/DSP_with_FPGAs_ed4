-- This is a generic DLMS FIR filter generator 
-- It uses W1 bit data/coefficients bits

LIBRARY ieee; USE ieee.std_logic_1164.ALL;
PACKAGE n_bit_int IS               -- User defined types
  CONSTANT W1 : INTEGER := 8;  -- Input bit width
  CONSTANT W2 : INTEGER := 16; -- Multiplier bit width 2*W1
  SUBTYPE SLV1 IS STD_LOGIC_VECTOR(W1-1 DOWNTO 0);
  SUBTYPE SLV2 IS STD_LOGIC_VECTOR(W2-1 DOWNTO 0);
END n_bit_int;
LIBRARY work; USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY fir4dlms IS                       ------> Interface
  GENERIC (L     : INTEGER := 2);  -- Filter taps  
  PORT ( clk    : IN  STD_LOGIC;  -- System clock
         reset  : IN  STD_LOGIC;  -- Asynchronous reset
         x_in   : IN  SLV1;       -- System input
         d_in   : IN  SLV1;       -- Reference input
         f0_out : OUT SLV1;       -- 1. filter coefficient
         f1_out : OUT SLV1;       -- 2. filter coefficient
         y_out  : OUT SLV2;       -- System output
         e_out  : OUT SLV2);      -- Error signal
END fir4dlms;
-- --------------------------------------------------------
ARCHITECTURE fpga OF fir4dlms IS

  TYPE ARRAY_F IS ARRAY (0 TO L-1) OF SLV1;
  TYPE ARRAY_X IS ARRAY (0 TO 4) OF SLV1;
  TYPE ARRAY_D IS ARRAY (0 TO 2) OF SLV1;
  TYPE A0_L1SLV2 IS ARRAY (0 TO L-1) OF SLV2;

  SIGNAL  xemu0, xemu1 :  SLV1;
  SIGNAL  emu     :  SLV1;
  SIGNAL  y, sxty :  SLV2;

  SIGNAL  e, sxtd  :  SLV2;
  SIGNAL  f        :  ARRAY_F; -- Coefficient array 
  SIGNAL  x        :  ARRAY_X; -- Data array 
  SIGNAL  d        :  ARRAY_D; -- Reference array 
  SIGNAL  p, xemu  :  A0_L1SLV2;  -- Product array 
                                          
BEGIN

  dsxt: PROCESS (d)  -- make d a 16 bit number
  BEGIN
    sxtd(7 DOWNTO 0) <= d(2);
    FOR k IN 15 DOWNTO 8 LOOP
      sxtd(k) <= d(2)(7);
    END LOOP;
  END PROCESS;

  Store: PROCESS (clk, reset)   ------> Store these data or
  BEGIN                        -- coefficients in registers
    IF reset = '1' THEN               -- Asynchronous clear
      FOR k IN 0 TO 2 LOOP
        d(k)  <= (OTHERS => '0'); 
      END LOOP;
      FOR k IN 0 TO 4 LOOP
        x(k)  <= (OTHERS => '0'); 
      END LOOP;
      FOR k IN 0 TO 1 LOOP
        f(k)  <= (OTHERS => '0'); 
      END LOOP;                
    ELSIF rising_edge(clk) THEN  
      d(0) <= d_in;   -- Shift register for desired data
      d(1) <= d(0);
      d(2) <= d(1);
      x(0) <= x_in;   -- Shift register for data          
      x(1) <= x(0);
      x(2) <= x(1);
      x(3) <= x(2);
      x(4) <= x(3);
      f(0) <= f(0) + xemu(0)(15 DOWNTO 8); -- implicit 
      f(1) <= f(1) + xemu(1)(15 DOWNTO 8); -- divide by 2
    END IF;
  END PROCESS Store;

 Mul: PROCESS (clk, reset)   ------> Store these data or
  BEGIN                        -- coefficients in registers
    IF reset = '1' THEN               -- Asynchronous clear
      FOR k IN 0 TO L-1 LOOP
        p(k)  <= (OTHERS => '0'); 
        xemu(k)  <= (OTHERS => '0');         
      END LOOP;
      y <=  (OTHERS => '0'); 
      e <=  (OTHERS => '0');                    
    ELSIF rising_edge(clk) THEN  
      FOR I IN 0 TO L-1 LOOP
        p(i) <= f(i) * x(i);
        xemu(i) <= emu * x(i+3);        
      END LOOP;
      y <= p(0) + p(1);  -- Computer ADF output:log(L) adds
      e <= sxtd - sxty;  -- e*mu divide by 2 and 2
    END IF;
  END PROCESS Mul;

  emu <= e(8 DOWNTO 1);    -- from xemu makes mu=1/4                            

  ysxt: PROCESS (y) -- scale y by 128 because x is fraction
  BEGIN
    sxty(8 DOWNTO 0) <= y(15 DOWNTO 7);
    FOR k IN 15 DOWNTO 9 LOOP
      sxty(k) <= y(y'high);
    END LOOP;
  END PROCESS;

  y_out <= sxty;    -- Monitor some test signals
  e_out <= e;
  f0_out <= f(0);
  f1_out <= f(1);

END fpga;

