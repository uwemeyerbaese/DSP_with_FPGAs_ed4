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
ENTITY iir5para_nwrap IS                      ------> Interface
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
ARCHITECTURE fpga OF iir5para_nwrap  IS
  -- SUBTYPE FIX : IS SFIXED(1 DOWNTO -19); 
-- First BiQuad coefficients
  CONSTANT a12 : SFIXED(1 DOWNTO -19) 
                          := TO_SFIXED(-1.99484680, 1,-19);
  CONSTANT  a13 : SFIXED(1 DOWNTO -19) 
                           := TO_SFIXED(0.99591112, 1,-19);
  CONSTANT  b11 : SFIXED(1 DOWNTO -19) 
                           := TO_SFIXED(0.00307256, 1,-19);  
  CONSTANT  b12 : SFIXED(1 DOWNTO -19) 
                          := TO_SFIXED(-0.00316061, 1,-19);
-- Second BiQuad coefficients  
  CONSTANT  a22 : SFIXED(1 DOWNTO -19) 
                          := TO_SFIXED(-1.98467605, 1,-19);
  CONSTANT  a23 : SFIXED(1 DOWNTO -19) 
                           := TO_SFIXED(0.98524428, 1,-19);
  CONSTANT  b21 : SFIXED(1 DOWNTO -19) 
                          := TO_SFIXED(-0.01464265, 1,-19);
  CONSTANT  b22 : SFIXED(1 DOWNTO -19) 
                           := TO_SFIXED(0.01464684, 1,-19);
-- First order system with R(5) and P(5)
  CONSTANT  a32 : SFIXED(1 DOWNTO -19) 
                           := TO_SFIXED(0.98867974, 1,-19);  
  CONSTANT  b31 : SFIXED(1 DOWNTO -19) 
                             := TO_SFIXED(0.012170, 1,-19);
-- Direct system   
  CONSTANT  D : SFIXED(1 DOWNTO -19) 
                             := TO_SFIXED(0.000304, 1,-19);
-- Internal signals  
  SIGNAL  s11, s12, s21, s22, s31  : 
                   SFIXED(1 DOWNTO -19) := (OTHERS => '0');
  SIGNAL  x, y, r12, r13, r22, r23, r32  : 
                   SFIXED(1 DOWNTO -19) := (OTHERS => '0'); 
  SIGNAL  r41, r42, r43  : 
                   SFIXED(1 DOWNTO -19) := (OTHERS => '0'); 
  SIGNAL  x32, y_sfix, y_D, y_1, y_21, y_22 
                                   : SFIXED(15 DOWNTO -16);  

BEGIN
 
  x32 <= TO_SFIXED(x_in, x32); -- redefine bits as FIX 16.16 number
  x <= resize(x32, x); -- Internal precision is 2.19 format

  P1: PROCESS (clk, x, reset)            ------> Behavioral Style 
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
    s12 <= resize(    b12 * x,x);
    s11 <= resize(s12+b11*x,x);
    r13 <= resize(s11-a13*r12,x);
    r12 <= resize(r13-a12*r12,x);
-- 2. BiQuad is 2. order
    s22 <= resize(   b22 * x,x);
    s21 <= resize(s22+b21*x,x);
    r23 <= resize(s21-a23*r22,x);
    r22 <= resize(r23-a22*r22,x);
-- 3. Section is 1. order
    s31 <= resize(    b31 * x,x);
    r32 <= resize(s31+a32*r32,x);
-- 4. Section is constant 
    r41 <= resize(  D * x,x);
-- Output adder tree      
    r42 <= r41;
    r43 <= resize(r42 + r32,x);
    y <= resize(r12+r22+r43,x);
    END IF;                                      -- Output Sum
  END PROCESS;

-- Convert to 16.16 sfixed number
  y_sfix <= resize(y, y_sfix);
  y_D  <= resize(r42, y_sfix);
  y_1  <= resize(r32, y_sfix);
  y_21 <= resize(r22, y_sfix);
  y_22 <= resize(r12, y_sfix);
-- Redefine bits as 32 bit SLV
  y_out <= to_slv(y_sfix);
  y_Dout <= to_slv(y_D);  
  y_1out <= to_slv(y_1);
  y_21out <= to_slv(y_21);
  y_22out <= to_slv(y_22);
  
END fpga;