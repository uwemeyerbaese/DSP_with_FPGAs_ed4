-- This is a generic LMS FIR filter generator 
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
ENTITY fir_lms IS                      ------> Interface
  GENERIC (L  : INTEGER := 2);    -- Filter length 
  PORT ( clk    : IN  STD_LOGIC;  -- System clock
         reset  : IN  STD_LOGIC;  -- Asynchronous reset
         x_in   : IN  SLV1;       -- System input
         d_in   : IN  SLV1;       -- Reference input
         f0_out : OUT SLV1;       -- 1. filter coefficient
         f1_out : OUT SLV1;       -- 2. filter coefficient
         y_out  : OUT SLV2;       -- System output
         e_out  : OUT SLV2);      -- Error signal
END fir_lms;
-- --------------------------------------------------------
ARCHITECTURE fpga OF fir_lms IS

  TYPE A0_L1SLV1 IS ARRAY (0 TO L-1) OF SLV1;
  TYPE A0_L1SLV2 IS ARRAY (0 TO L-1) OF SLV2;

  SIGNAL  d       : SLV1;
  SIGNAL  emu     : SLV1;
  SIGNAL  y, sxty : SLV2;
  SIGNAL  e, sxtd : SLV2;
  SIGNAL  x, f    : A0_L1SLV1; -- Coeff/Data arrays
  SIGNAL  p, xemu : A0_L1SLV2; -- Product arrays
                                                        
BEGIN

  dsxt: PROCESS (d)  -- 16 bit signed extension for input d
  BEGIN
    sxtd(7 DOWNTO 0) <= d;
    FOR k IN 15 DOWNTO 8 LOOP
      sxtd(k) <= d(d'high);
    END LOOP;
  END PROCESS;
  
  Store: PROCESS(clk, reset) --> Store data or coefficients
  BEGIN
    IF reset = '1' THEN               -- Asynchronous clear
      d  <= (OTHERS => '0'); 
      x(0)  <= (OTHERS => '0'); x(1)  <= (OTHERS => '0'); 
      f(0)  <= (OTHERS => '0'); f(1)  <= (OTHERS => '0');     
    ELSIF rising_edge(clk) THEN  
      d    <= d_in;
      x(0) <= x_in;           
      x(1) <= x(0);
      f(0) <= f(0) + xemu(0)(15 DOWNTO 8); -- implicit 
      f(1) <= f(1) + xemu(1)(15 DOWNTO 8); -- divide by 2
    END IF;
  END PROCESS Store;
 
  MulGen1: FOR I IN 0 TO L-1 GENERATE 
    p(i) <= f(i) * x(i);
  END GENERATE;

  y <= p(0) + p(1);  -- Compute ADF output

  ysxt: PROCESS (y) -- Scale y by 128 because x is fraction
  BEGIN
    sxty(8 DOWNTO 0) <= y(15 DOWNTO 7);
    FOR k IN 15 DOWNTO 9 LOOP
      sxty(k) <= y(y'high);
    END LOOP;
  END PROCESS;

  e <= sxtd - sxty;
  emu <= e(8 DOWNTO 1);    -- e*mu divide by 2 and 
                           -- 2 from xemu makes mu=1/4
  MulGen2: FOR I IN 0 TO L-1 GENERATE 
    xemu(i) <= emu * x(i);
  END GENERATE;

    y_out  <= sxty;    -- Monitor some test signals
    e_out  <= e;
    f0_out <= f(0);
    f1_out <= f(1);

END fpga;