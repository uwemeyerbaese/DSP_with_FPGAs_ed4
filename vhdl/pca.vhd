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
ENTITY pca IS                      ------> Interface
 PORT (clk     : IN STD_LOGIC; -- System clock
       reset   : IN STD_LOGIC; -- System reset
       s1_in   : IN SLV32;     -- 1. signal input
       s2_in   : IN SLV32;     -- 2. signal input
       mu1_in  : IN SLV32;     -- Learning rate 1. PC 
       mu2_in  : IN SLV32;     -- Learning rate 2. PC
       x1_out  : OUT SLV32;    -- Mixing 1. output
       x2_out  : OUT SLV32;    -- Mixing 2. output
       w11_out : OUT SLV32;    -- Eigenvector [1,1]
       w12_out : OUT SLV32;    -- Eigenvector [1,2]
       w21_out : OUT SLV32;    -- Eigenvector [2,1]
       w22_out : OUT SLV32;    -- Eigenvector [2,2]
       y1_out  : OUT SLV32;    -- 1. PC output
       y2_out  : OUT SLV32);   -- 2. PC output
END;                          
-- --------------------------------------------------------
ARCHITECTURE fpga OF pca IS

  CONSTANT  a11 : SFIXED(15 DOWNTO -16) := 
                                   TO_SFIXED(0.75, 15,-16);
  CONSTANT  a12 : SFIXED(15 DOWNTO -16) := 
                                    TO_SFIXED(1.5, 15,-16);
  CONSTANT  a21 : SFIXED(15 DOWNTO -16) := 
                                    TO_SFIXED(0.5, 15,-16);
  CONSTANT  a22 : SFIXED(15 DOWNTO -16) := 
                              TO_SFIXED(0.333333, 15,-16);
  CONSTANT  ini : SFIXED(15 DOWNTO -16) := 
                                    TO_SFIXED(0.5, 15,-16);                  
  SIGNAL  s, s1, s2, x1, x2, w11, w12, w21, w22, mu1, mu2:
                  SFIXED(15 DOWNTO -16) := (OTHERS => '0');
BEGIN
 
  s1 <= TO_SFIXED(s1_in, s); -- redefine bits as signed
  s2 <= TO_SFIXED(s2_in, s); -- FIX 16.16 number
  mu1 <= TO_SFIXED(mu1_in, s);
  mu2 <= TO_SFIXED(mu2_in, s);

  P1: PROCESS (reset, clk, s1, s2)            
  VARIABLE h11, h12, y1, y2  : 
                  SFIXED(15 DOWNTO -16) := (OTHERS => '0');
  ------> Behavioral Style 
  BEGIN   -- reset/initialize all registers
    IF reset = '1' THEN -- reset all register
      x1 <= (OTHERS => '0');  x2 <= (OTHERS => '0'); 
      w11 <= ini;  w12 <= ini; 
      w21 <= ini;  w22 <= ini;        
    ELSIF rising_edge(clk) THEN  -- PCA using Sanger GHA
      -- Using the "do not WRAP"
     -- Mixing matrix
     x1<=resize(a11*s1+a12*s2,s,fixed_wrap,fixed_truncate);
     x2<=resize(a21*s1-a22*s2,s,fixed_wrap,fixed_truncate);
     -- first PC and eigenvector
     y1:=resize(x1*w11+x2*w12,s,fixed_wrap,fixed_truncate);
     h11 := resize(w11*y1,s,fixed_wrap,fixed_truncate);
     w11 <= resize(w11+mu1*(x1-h11)*y1,s,
                                fixed_wrap,fixed_truncate);
     h12 := resize(w12*y1,s,fixed_wrap,fixed_truncate);
     w12 <= resize(w12+mu1*(x2-h12)*y1,s,
                                fixed_wrap,fixed_truncate);
     -- second PC and eigenvector
     y2:=resize(x1*w21+x2*w22,s,fixed_wrap,fixed_truncate);
     w21 <= resize(w21+mu2*(x1-h11-w21*y2)*y2,s,
                                fixed_wrap,fixed_truncate);
     w22 <= resize(w22+mu2*(x2-h12-w22*y2)*y2,s,
                                fixed_wrap,fixed_truncate);
     -- registers y output
     y1_out <= to_slv(y1);
     y2_out <= to_slv(y2);
    END IF;
  END PROCESS;

  -- Redefine bits as 32 bit SLV
  x1_out <= to_slv(x1);
  x2_out <= to_slv(x2);
  w11_out <= to_slv(w11);
  w12_out <= to_slv(w12);
  w21_out <= to_slv(w21);
  w22_out <= to_slv(w22);
  
END fpga;
