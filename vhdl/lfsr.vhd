LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- --------------------------------------------------------
ENTITY lfsr IS                      ------> Interface
  PORT ( clk      : IN STD_LOGIC;    -- System clock
         reset    : IN  STD_LOGIC;   -- Asynchronous reset
         y   : OUT STD_LOGIC_VECTOR(6 DOWNTO 1)); 
END lfsr;                                  -- System output
-- --------------------------------------------------------
ARCHITECTURE fpga OF lfsr IS

  SIGNAL  ff  :   STD_LOGIC_VECTOR(6 DOWNTO 1);  
  
BEGIN

  PROCESS(clk, reset)
  BEGIN                -- Implement length 6 LFSR with xnor
    IF reset = '1' THEN               -- Asynchronous clear
      ff  <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN 
      ff(1) <=  NOT (ff(5) XOR ff(6));
      FOR I IN 6 DOWNTO 2 LOOP    -- Tapped delay line: 
        ff(I) <= ff(I-1);         -- shift one 
      END LOOP;
    END IF;
  END PROCESS ;

  y <= ff; -- Connect to I/O cell
  
END fpga;
