PACKAGE n_bit_int IS    -- User defined types
  SUBTYPE S8 IS INTEGER RANGE -128 TO 127;
  TYPE A0_3S8 IS ARRAY (0 TO 3) OF S8;
END n_bit_int;

LIBRARY work;
USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- --------------------------------------------------------
ENTITY fir_srg IS                         ------> Interface
  PORT (clk   :   IN  STD_LOGIC; -- System clock
        reset :   IN  STD_LOGIC; -- Asynchron reset
        x     :   IN  S8;        -- System input
        y     :   OUT S8);       -- System output
END fir_srg;
-- --------------------------------------------------------
ARCHITECTURE fpga OF fir_srg IS

  SIGNAL tap : A0_3S8;   -- Tapped delay line of bytes
  
BEGIN

  P1: PROCESS(clk, reset, x, tap)     ------> Behavioral Style
  BEGIN
    IF reset = '1' THEN   -- clear shift register
      FOR K IN 0 TO 3 LOOP
        tap(K) <= 0;
      END LOOP;
      y <= 0;
    ELSIF rising_edge(clk) THEN
  -- Compute output y with the filter coefficients weight.
  -- The coefficients are [-1  3.75  3.75  -1]. 
  -- Division for Altera VHDL is only allowed for 
  -- powers-of-two values!
      y <= 2 * tap(1) + tap(1) + tap(1) / 2 + tap(1) / 4 
         + 2 * tap(2) + tap(2) + tap(2) / 2 + tap(2) / 4
         - tap(3) - tap(0);
      FOR I IN 3 DOWNTO 1 LOOP 
        tap(I) <= tap(I-1); -- Tapped delay line: shift one
      END LOOP;
    END IF;
    tap(0) <= x;                -- Input in register 0
  END PROCESS;

END fpga;
