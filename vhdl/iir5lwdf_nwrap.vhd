-----------------------------------------------------------
-- Description: 5 th order Lattice Wave Digital Filter 
-- Coefficients gamma: 
-- 0.988739 -0.000519 -1.995392 -0.000275 -1.985016 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

LIBRARY ieee_proposed;
 use ieee_proposed.fixed_float_types.all;
 use ieee_proposed.fixed_pkg.all;
 use ieee_proposed.float_pkg.all;
-- --------------------------------------------------------
ENTITY iir5lwdf IS                      ------> Interface
 PORT (clk   : IN STD_LOGIC; -- System clock
       reset : IN STD_LOGIC; -- System reset
  x_in  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- System input
  y_ap1out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- AP1 out
  y_ap2out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- AP2 out 
  y_ap3out: OUT STD_LOGIC_VECTOR(31 DOWNTO 0); -- AP3 out
  y_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));  -- System 
END;                                           -- output
-- --------------------------------------------------------
ARCHITECTURE fpga OF iir5lwdf IS
-- Coefficients gamma
  CONSTANT g1 : SFIXED(6 DOWNTO -15) := 
                                TO_SFIXED(0.988739, 6,-15);
  CONSTANT g2 : SFIXED(6 DOWNTO -15) := 
                               TO_SFIXED(-0.000519, 6,-15);
  CONSTANT g3 : SFIXED(6 DOWNTO -15) := 
                               TO_SFIXED(-1.995392, 6,-15);  
  CONSTANT g4 : SFIXED(6 DOWNTO -15) := 
                               TO_SFIXED(-0.000275, 6,-15);
  CONSTANT g5 : SFIXED(6 DOWNTO -15) := 
                               TO_SFIXED(-1.985016, 6,-15);
-- Internal signals  
  SIGNAL  c1, c2, c3, l2, l3  : SFIXED(6 DOWNTO -15) := 
                                           (OTHERS => '0');
  SIGNAL  x, ap1, ap2, ap3, ap3r, y  : SFIXED(6 DOWNTO -15)
                                        := (OTHERS => '0'); 
  SIGNAL  x32, y_sfix, y_ap1, y_ap2, y_ap3 : 
                                     SFIXED(15 DOWNTO -16);
BEGIN
 
  x32 <= TO_SFIXED(x_in, x32); -- redefine bits as FIX 16.16
  x <= resize(x32, x); -- Internal precision is 6.19 format

  P1: PROCESS (clk, x, reset)     ----> Behavioral Style 
    VARIABLE p1, a4, a5, a6, a8, a9, a10 : 
         SFIXED(6 DOWNTO -15) := (OTHERS => '0'); -- No FFs
  BEGIN   -- First equations without infering registers
    IF reset = '1' THEN -- reset all registered
      y <= (OTHERS => '0'); 
      c1 <= (OTHERS => '0'); ap1 <= (OTHERS => '0');
      c2 <= (OTHERS => '0'); l2 <= (OTHERS => '0');
      ap2 <= (OTHERS => '0'); 
      c3 <= (OTHERS => '0'); l3 <= (OTHERS => '0'); 
      ap3 <= (OTHERS => '0'); ap3r <= (OTHERS => '0'); 
    ELSIF rising_edge(clk) THEN -- AP LWDF form
-- 1. AP section is 1. order
      p1 := resize(g1 *(c1-x),x);
      c1 <= resize(x + p1,x);
      ap1 <= resize(c1 + p1,x);
-- 2. AP section is 2. order
      a4 := resize(ap1-l2+ c2,x);
      a5 := resize(a4 * g2+c2,x);
      a6 := resize(a4 * g3-l2,x);
      c2 <= resize(a5,x);
      l2 <= resize(a6,x);
      ap2 <= resize(-a5-a6-a4,x);
-- 3. AP section is 2. order
      a8 := resize(x - l3 +c3,x);
      a9 := resize(a8 * g4+c3,x);
      a10 := resize(a8 *g5-l3,x);
      c3 <= resize(a9,x);
      l3 <= resize(a10,x);
      ap3 <=resize(-a9-a10-a8,x);
      ap3r <= ap3; -- extra register due to AP1
-- Output adder
      y <= resize(ap3r + ap2,x); 
    END IF;                                   -- Output sum
  END PROCESS;

-- Convert to 16.16 sfixed number
  y_sfix <= resize(y, y_sfix);
  y_ap1  <= resize(ap1, y_sfix);
  y_ap2  <= resize(ap2, y_sfix);
  y_ap3  <= resize(ap3, y_sfix);
-- Redefine bits as 32 bit SLV
  y_out <= to_slv(y_sfix);
  y_ap1out <= to_slv(y_ap1);  
  y_ap2out <= to_slv(y_ap2);
  y_ap3out <= to_slv(y_ap3);
  
END fpga;
