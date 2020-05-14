LIBRARY ieee; USE ieee.std_logic_1164.ALL;
PACKAGE n_bit_int IS               -- User defined types
  SUBTYPE SLV32 IS STD_LOGIC_VECTOR(31 DOWNTO 0);
END n_bit_int;
LIBRARY work; USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

LIBRARY ieee_proposed;
USE ieee_proposed.fixed_float_types.ALL;
USE ieee_proposed.fixed_pkg.ALL;
USE ieee_proposed.float_pkg.ALL;
-- --------------------------------------------------------
ENTITY ica IS                      ------> Interface
 PORT (clk    : IN STD_LOGIC; -- System clock
       reset  : IN STD_LOGIC; -- System reset
       s1_in  : IN SLV32;     -- 1. signal input
       s2_in  : IN SLV32;     -- 2. signal input
       mu_in  : IN SLV32;     -- Learning rate      
       x1_out : OUT SLV32;    -- Mixing 1. output
       x2_out : OUT SLV32;    -- Mixing 2. output
       B11_out : OUT SLV32;    -- Demixing 1,1
       B12_out : OUT SLV32;    -- Demixing 1,2
       B21_out : OUT SLV32;    -- Demixing 2,1
       B22_out : OUT SLV32;    -- Demixing 2,2
       y1_out : OUT SLV32;    -- 1. component output
       y2_out : OUT SLV32);   -- 2. component output
END;                          
-- --------------------------------------------------------
ARCHITECTURE fpga OF ica IS

  CONSTANT  a11 : SFIXED(15 DOWNTO -16) := 
                                   TO_SFIXED(0.75, 15,-16);
  CONSTANT  a12 : SFIXED(15 DOWNTO -16) := 
                                    TO_SFIXED(1.5, 15,-16);
  CONSTANT  a21 : SFIXED(15 DOWNTO -16) := 
                                    TO_SFIXED(0.5, 15,-16);
  CONSTANT  a22 : SFIXED(15 DOWNTO -16) := 
                               TO_SFIXED(0.333333, 15,-16);
  CONSTANT  one : SFIXED(15 DOWNTO -16) := 
                                    TO_SFIXED(1.0, 15,-16);
  CONSTANT  negone : SFIXED(15 DOWNTO -16) := 
                                   TO_SFIXED(-1.0, 15,-16);
  SIGNAL  s, s1, s2, x1, x2, B11, B12, B21, B22, mu  : 
                  SFIXED(15 DOWNTO -16) := (OTHERS => '0');
BEGIN
 
  s1 <= TO_SFIXED(s1_in, s); -- redefine bits as
  s2 <= TO_SFIXED(s2_in, s); -- signed FIX 16.16 number
  mu <= TO_SFIXED(mu_in, s);

  P1: PROCESS (reset, clk, s1, s2)   -- ICA using EASI         
  VARIABLE f1, f2, y1, y2, H11, H12, H21, H22, DB11, DB12,
     DB21, DB22 : SFIXED(15 DOWNTO -16) := (OTHERS => '0');
  BEGIN  
    IF reset = '1' THEN -- reset x register and set B=I
      x1 <= (OTHERS => '0');  x2 <= (OTHERS => '0'); 
      B11 <= one;  B12 <= (OTHERS => '0'); 
      B21 <= (OTHERS => '0');  B22 <= one;        
    ELSIF rising_edge(clk) THEN  
   -- Mixing matrix
   x1 <= resize(a11*s1+a12*s2,s,fixed_wrap,fixed_truncate);
   x2 <= resize(a21*s1-a22*s2,s,fixed_wrap,fixed_truncate);
  -- New y values first 
   y1 := resize(x1*B11+x2*B12,s,fixed_wrap,fixed_truncate);
   y2 := resize(x1*B21+x2*B22,s,fixed_wrap,fixed_truncate);
     -- compute the H matrix 
  f1 := y1; -- Build tanh approximation function for f1
  IF y1 > one THEN f1 := one; END IF;
  IF y1 < negone THEN f1 := negone; END IF;
  f2 := y2; -- Build tanh approximation function for f2
  IF y2 > one THEN f2 := one; END IF;
  IF y2 < negone THEN f2 := negone; END IF;
  H11:=resize(one - y1*y1,s,fixed_wrap,fixed_truncate);
H12:=resize(f1*y2-y1*y2-y1*f2,s,fixed_wrap,fixed_truncate);
H21:=resize(f2*y1-y2*y1-y2*f1,s,fixed_wrap,fixed_truncate);
  H22:= resize(one - y2*y2,s,fixed_wrap,fixed_truncate);
     -- update matrix Delta B 
 DB11:=resize(B11*H11+H12*B21,s,fixed_wrap,fixed_truncate);
 DB12:=resize(B12*H11+H12*B22,s,fixed_wrap,fixed_truncate);
 DB21:=resize(B11*H21+H22*B21,s,fixed_wrap,fixed_truncate);
 DB22:=resize(B12*H21+H22*B22,s,fixed_wrap,fixed_truncate);
   -- Store update matrix B in registers  
  B11 <= resize(B11 + mu*DB11,s,fixed_wrap,fixed_truncate);
  B12 <= resize(B12 + mu*DB12,s,fixed_wrap,fixed_truncate);
  B21 <= resize(B21 + mu*DB21,s,fixed_wrap,fixed_truncate);
  B22 <= resize(B22 + mu*DB22,s,fixed_wrap,fixed_truncate);
     -- register y output
     y1_out <= to_slv(y1);
     y2_out <= to_slv(y2);
    END IF;
  END PROCESS;

  x1_out  <= to_slv(x1); -- Redefine bits as 32 bit SLV
  x2_out  <= to_slv(x2);
  B11_out <= to_slv(B11);
  B12_out <= to_slv(B12);
  B21_out <= to_slv(B21);
  B22_out <= to_slv(B22);
  
END fpga;
