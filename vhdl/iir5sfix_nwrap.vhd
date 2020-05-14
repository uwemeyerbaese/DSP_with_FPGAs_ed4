-- --------------------------------------------------------
-- Description:   This is a 5 th order IIR in direct form  
--                implementation. 
-- Feedforward coefficients B=
--   0.000304 -0.000909 0.000605 
--   0.000605 -0.000909 0.000304 
-- Feedback coefficients A=
--   1.000000 -4.968203  9.874754 
--   -9.815007 4.878564 -0.970108 
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL; USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

LIBRARY ieee_proposed;
USE ieee_proposed.fixed_float_types.ALL;
USE ieee_proposed.fixed_pkg.ALL;
USE ieee_proposed.float_pkg.ALL;
-- --------------------------------------------------------
ENTITY iir5sfix_nwrap IS                      ------> Interface
 PORT (clk    : IN STD_LOGIC; -- System clock
       reset  : IN STD_LOGIC; -- System reset
       switch : IN STD_LOGIC; -- Feedback switch
       x_in   : IN STD_LOGIC_VECTOR(63 DOWNTO 0); 
                                            -- System input
       t_out  : BUFFER STD_LOGIC_VECTOR(39 DOWNTO 0); 
                                                -- Feedback
       y_out  : OUT STD_LOGIC_VECTOR(39 DOWNTO 0)); 
END;                                        --System output
-- --------------------------------------------------------
ARCHITECTURE fpga OF iir5sfix_nwrap  IS

  CONSTANT  a2 : SFIXED(4 DOWNTO -30) := 
                           TO_SFIXED(-4.9682025852, 4,-30);
  CONSTANT  a3 : SFIXED(5 DOWNTO -30) := 
                            TO_SFIXED(9.8747536754, 5,-30);
  CONSTANT  a4 : SFIXED(5 DOWNTO -30) := 
                           TO_SFIXED(-9.8150069021, 5,-30);
  CONSTANT  a5 : SFIXED(4 DOWNTO -30) := 
                            TO_SFIXED(4.8785639415, 4,-30);
  CONSTANT  a6 : SFIXED(1 DOWNTO -30) := 
                           TO_SFIXED(-0.9701081227, 1,-30);
  CONSTANT  b1 : SFIXED(0 DOWNTO -30) := 
                            TO_SFIXED(0.0003035737, 0,-30);  
  CONSTANT  b2 : SFIXED(0 DOWNTO -30) := 
                           TO_SFIXED(-0.0009085259, 0,-30);
  CONSTANT  b3 : SFIXED(0 DOWNTO -30) := 
                            TO_SFIXED(0.0006049556, 0,-30);
  CONSTANT  b4 : SFIXED(0 DOWNTO -30) := 
                            TO_SFIXED(0.0006049556, 0,-30);
  CONSTANT  b5 : SFIXED(0 DOWNTO -30) := 
                           TO_SFIXED(-0.0009085259, 0,-30);  
  CONSTANT  b6 : SFIXED(0 DOWNTO -30) := 
                            TO_SFIXED(0.0003035737, 0,-30);
  SIGNAL  h, s1, s2, s3, s4, s5  : 
                  SFIXED(33 DOWNTO -30) := (OTHERS => '0');
  SIGNAL  x, y, t, r2, r3, r4, r5  : 
                  SFIXED(33 DOWNTO -30) := (OTHERS => '0'); 
  SIGNAL  y_sfix, t_sfix : SFIXED(23 DOWNTO -16);  
  
BEGIN
 
  x <= TO_SFIXED(x_in, x); -- redefine bits as FIX 34.30 number
  
  P1: PROCESS (reset, clk, x, t, s1, s2, s3, s4, s5, r2, r3, h)            
  ------> Behavioral Style 
  BEGIN   -- First equations without infering registers
    IF switch = '0' THEN
      h <= x; -- Switch is open
    ELSE      
      h <= resize(x - t, x, fixed_wrap,fixed_truncate); 
    END IF;                      -- Switch is closed
    IF reset = '1' THEN -- reset all register
      t <= (OTHERS => '0');  y <= (OTHERS => '0'); 
      r2 <= (OTHERS => '0'); r3 <= (OTHERS => '0');
      r4 <= (OTHERS => '0'); r5 <= (OTHERS => '0');
      s1 <= (OTHERS => '0'); s2 <= (OTHERS => '0');
      s3 <= (OTHERS => '0'); s4 <= (OTHERS => '0');
      s5 <= (OTHERS => '0');  
    ELSIF rising_edge(clk) THEN  -- IIR in direct form
      -- Using the "do not WRAP"
     r5 <= resize(     a6 * h,x);
     r4 <= resize(r5 + a5 * h,x);
     r3 <= resize(r4 + a4 * h,x);
     r2 <= resize(r3 + a3 * h,x);
     t  <= resize(r2 + a2 * h,x);
     s5 <= resize(     b6 * h,x);
     s4 <= resize(s5 + b5 * h,x);
     s3 <= resize(s4 + b4 * h,x);
     s2 <= resize(s3 + b3 * h,x);
     s1 <= resize(s2 + b2 * h,x);
     y  <= resize(s1 + b1 * h,x);
    END IF;
  END PROCESS;

  -- Convert to 24.16 sfixed number
  y_sfix  <= resize(y, y_sfix);
  t_sfix  <= resize(t, t_sfix);
  -- Redefine bits as 40 bit SLV
  y_out <= to_slv(y_sfix);
  t_out <= to_slv(t_sfix);

END fpga;
