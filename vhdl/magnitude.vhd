PACKAGE N_bit_int IS    -- User define types
  SUBTYPE S16 IS INTEGER RANGE -2**15 TO 2**15-1;
END N_bit_int;

LIBRARY work; USE work.N_bit_int.ALL;

LIBRARY ieee;              -- Using predefined Packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- --------------------------------------------------------
ENTITY magnitude IS                 ------> Interface
 PORT (clk      : IN  STD_LOGIC;    -- System clock
       reset    : IN  STD_LOGIC;    -- Asynchron reset
       x, y         : IN S16;       -- System inputs
       r            : OUT S16 :=0); -- System output
END;
-- --------------------------------------------------------
ARCHITECTURE fpga OF magnitude IS 
  SIGNAL x_r, y_r : S16 := 0;
BEGIN
  -- approximate the magnitude via 
  -- r = alpha*max(|x|,|y|) + beta*min(|x|,|y|)
  -- use alpha=1 and beta=1/4
  PROCESS(clk, reset, x, y, x_r, y_r) 
  VARIABLE mi, ma, ax, ay : S16 := 0; --  temporals
  BEGIN
    IF reset = '1' THEN     -- Asynchronous clear
      x_r  <= 0; y_r <= 0;
    ELSIF rising_edge(clk) THEN
      x_r <= x; y_r <= y;
    END IF;
    ax := ABS(x_r); -- take absolute values first
    ay := ABS(y_r);
    IF ax > ay THEN -- Determine max and min values
      mi := ay;
      ma := ax;
    ELSE
      mi := ax;
      ma := ay;
    END IF;
    IF reset = '1' THEN     -- Asynchronous clear
      r <= 0; 
    ELSIF rising_edge(clk) THEN
      r <= ma + mi/4; -- compute r=alpha*max+beta*min
    END IF;
  END PROCESS;
  
END fpga;
