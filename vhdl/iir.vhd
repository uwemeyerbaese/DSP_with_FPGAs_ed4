PACKAGE n_bit_int IS               -- User defined type
  SUBTYPE S15 IS INTEGER RANGE -2**14 TO 2**14-1;
END n_bit_int;

LIBRARY work;
USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- --------------------------------------------------------
ENTITY iir IS
  PORT (clk   : IN STD_LOGIC;   -- System clock
        reset : IN STD_LOGIC;   -- Asynchronous reset
        x_in  : IN  S15;        -- System input
        y_out : OUT S15);       -- Output result
END iir;
-- --------------------------------------------------------
ARCHITECTURE fpga OF iir IS

  SIGNAL x, y : S15;
 
BEGIN

  PROCESS(reset, clk, x_in, y) 
  BEGIN              -- Use FF for input and recursive part
    IF reset = '1' THEN -- Asynchronous clear
      x <= 0; y <= 0;
    ELSIF rising_edge(clk) THEN
      x  <= x_in;
      y  <= x + y / 4 + y / 2;
    END IF;
  END PROCESS;

  y_out <= y;           -- Connect y to output pins
  
END fpga;
