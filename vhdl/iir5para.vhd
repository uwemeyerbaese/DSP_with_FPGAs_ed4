-- --------------------------------------------------------
-- Description: 5 th order IIR parallel form implementation 
-- Coefficients: 
-- D =   0.00030357
-- B1 =  0.0031   -0.0032    0
-- A1 =  1.0000   -1.9948    0.9959
-- B2 = -0.0146    0.0146    0
-- A2 =  1.0000   -1.9847    0.9852
-- B3 =  0.0122
-- A3 =  0.9887

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

LIBRARY ieee_proposed;
 use ieee_proposed.fixed_float_types.all;
 use ieee_proposed.fixed_pkg.all;
 use ieee_proposed.float_pkg.all;
-- --------------------------------------------------------
ENTITY iir5para IS                      ------> Interface
 PORT (clk   : IN STD_LOGIC; -- System clock
       reset : IN STD_LOGIC; -- System reset
  x_in  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- System input
  y_Dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- 0 order
  y_1out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- 1. order 
  y_21out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);-- 2. order 1
  y_22out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- 2.order 2
  y_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)); -- System 
END;                                          -- output  
-- --------------------------------------------------------
ARCHITECTURE fpga OF iir5para IS
  -- SUBTYPE FIX : IS SFIXED(1 DOWNTO -18); 
-- First BiQuad coefficients
  CONSTANT a12 : SFIXED(1 DOWNTO -18) 
                          := TO_SFIXED(-1.99484680, 1,-18);
  CONSTANT  a13 : SFIXED(1 DOWNTO -18) 
                           := TO_SFIXED(0.99591112, 1,-18);
  CONSTANT  b11 : SFIXED(1 DOWNTO -18) 
                           := TO_SFIXED(0.00307256, 1,-18);  
  CONSTANT  b12 : SFIXED(1 DOWNTO -18) 
                          := TO_SFIXED(-0.00316061, 1,-18);
-- Second BiQuad coefficients  
  CONSTANT  a22 : SFIXED(1 DOWNTO -18) 
                          := TO_SFIXED(-1.98467605, 1,-18);
  CONSTANT  a23 : SFIXED(1 DOWNTO -18) 
                           := TO_SFIXED(0.98524428, 1,-18);
  CONSTANT  b21 : SFIXED(1 DOWNTO -18) 
                          := TO_SFIXED(-0.01464265, 1,-18);
  CONSTANT  b22 : SFIXED(1 DOWNTO -18) 
                           := TO_SFIXED(0.01464684, 1,-18);
-- First order system with R(5) and P(5)
  CONSTANT  a32 : SFIXED(1 DOWNTO -18) 
                           := TO_SFIXED(0.98867974, 1,-18);  
  CONSTANT  b31 : SFIXED(1 DOWNTO -18) 
                             := TO_SFIXED(0.012170, 1,-18);
-- Direct system   
  CONSTANT  D : SFIXED(1 DOWNTO -18) 
                             := TO_SFIXED(0.000304, 1,-18);
-- Internal signals  
  SIGNAL  s11, s12, s21, s22, s31  : 
                   SFIXED(1 DOWNTO -18) := (OTHERS => '0');
  SIGNAL  x, y, r12, r13, r22, r23, r32  : 
                   SFIXED(1 DOWNTO -18) := (OTHERS => '0'); 
  SIGNAL  r41, r42, r43  : 
                   SFIXED(1 DOWNTO -18) := (OTHERS => '0'); 
  SIGNAL  x32, y_sfix, y_D, y_1, y_21, y_22 
                                   : SFIXED(15 DOWNTO -16);  

BEGIN
 
  x32 <= TO_SFIXED(x_in, x32); -- redefine as 16.16 format
  x <= resize(x32, x); -- Internal precision is 2.19 format

  P1: PROCESS (clk, x, reset)      ------> Behavioral Style 
  BEGIN   -- First equations without infering registers
    IF reset = '1' THEN -- reset all registered
      y <= (OTHERS => '0'); 
      r12 <= (OTHERS => '0'); r13 <= (OTHERS => '0');
      r22 <= (OTHERS => '0'); r23 <= (OTHERS => '0');
      r32 <= (OTHERS => '0'); 
      r41 <= (OTHERS => '0'); r42 <= (OTHERS => '0'); 
      r43 <= (OTHERS => '0'); 
      s11 <= (OTHERS => '0'); s12 <= (OTHERS => '0');
      s21 <= (OTHERS => '0'); s22 <= (OTHERS => '0');
      s31 <= (OTHERS => '0'); 
    ELSIF rising_edge(clk) THEN -- SOS Modified BiQuad form
-- 1. BiQuad is 2. order
    s12 <= resize(    b12 * x,x,fixed_wrap,fixed_truncate);
    s11 <= resize(s12+b11*x,x,fixed_wrap,fixed_truncate);
    r13 <= resize(s11-a13*r12,x,fixed_wrap,fixed_truncate);
    r12 <= resize(r13-a12*r12,x,fixed_wrap,fixed_truncate);
-- 2. BiQuad is 2. order
    s22 <= resize(   b22 * x,x,fixed_wrap,fixed_truncate);
    s21 <= resize(s22+b21*x,x,fixed_wrap,fixed_truncate);
    r23 <= resize(s21-a23*r22,x,fixed_wrap,fixed_truncate);
    r22 <= resize(r23-a22*r22,x,fixed_wrap,fixed_truncate);
-- 3. Section is 1. order
    s31 <= resize(    b31 * x,x,fixed_wrap,fixed_truncate);
    r32 <= resize(s31+a32*r32,x,fixed_wrap,fixed_truncate);
-- 4. Section is constant 
    r41 <= resize(  D * x,x,fixed_wrap,fixed_truncate);
-- Output adder tree      
    r42 <= r41;
    r43 <= resize(r42 + r32,x,fixed_wrap,fixed_truncate);
    y <= resize(r12+r22+r43,x,fixed_wrap,fixed_truncate);
    END IF;                                      -- Output Sum
  END PROCESS;

-- Convert to 16.16 sfixed number
  y_sfix <= resize(y, y_sfix,fixed_wrap,fixed_truncate);
  y_D  <= resize(r42, y_sfix,fixed_wrap,fixed_truncate);
  y_1  <= resize(r32, y_sfix,fixed_wrap,fixed_truncate);
  y_21 <= resize(r22, y_sfix,fixed_wrap,fixed_truncate);
  y_22 <= resize(r12, y_sfix,fixed_wrap,fixed_truncate);
-- Redefine bits as 32 bit SLV
  y_out <= to_slv(y_sfix);
  y_Dout <= to_slv(y_D);  
  y_1out <= to_slv(y_1);
  y_21out <= to_slv(y_21);
  y_22out <= to_slv(y_22);
  
END fpga;