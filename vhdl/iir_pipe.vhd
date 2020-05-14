PACKAGE n_bit_int IS             -- User defined type
  SUBTYPE S15 IS INTEGER RANGE -2**14 TO 2**14-1;
END n_bit_int;

LIBRARY work;
USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- --------------------------------------------------------
ENTITY iir_pipe IS
  PORT ( clk   : IN  STD_LOGIC; -- System clock
         reset : IN  STD_LOGIC; -- Asynchronous reset
         x_in  : IN  S15;       -- System input
         y_out : OUT S15);      -- System output
END iir_pipe;
-- --------------------------------------------------------
ARCHITECTURE fpga OF iir_pipe IS

  SIGNAL  x, x3, sx, y, y9 : S15;
            
BEGIN

  PROCESS(clk, reset, x_in, x, x3, sx, y, y9)   
  BEGIN    -- Use FFs for input, output and pipeline stages
    IF reset = '1' THEN -- Asynchronous clear
      x <= 0; x3 <= 0; sx <= 0; y9 <= 0; y <= 0;
    ELSIF rising_edge(clk) THEN
      x   <= x_in;
      x3  <= x / 2 + x / 4;   -- Compute x*3/4
      sx <=  x + x3; -- Sum of x elements = output FIR part
      y9  <= y / 2 + y / 16;  -- Compute y*9/16
      y   <= sx + y9;         -- Compute output
    END IF;
  END PROCESS;

  y_out <= y ;    -- Connect register y to output pins
  
END fpga;
