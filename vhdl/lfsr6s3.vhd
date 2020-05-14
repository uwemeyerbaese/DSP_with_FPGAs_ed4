LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- --------------------------------------------------------
ENTITY lfsr6s3 IS                      ------> Interface
  PORT ( clk      : IN STD_LOGIC;    -- System clock
         reset    : IN  STD_LOGIC;   -- Asynchronous reset
         y   : OUT STD_LOGIC_VECTOR(6 DOWNTO 1)); 
END lfsr6s3;                               -- System output
-- --------------------------------------------------------
ARCHITECTURE fpga OF lfsr6s3 IS

  SIGNAL ff : STD_LOGIC_VECTOR(6 DOWNTO 1);  
  
BEGIN

  PROCESS(clk, reset)            -- Implement three step
  BEGIN                          -- length-6 LFSR with xnor
    IF reset = '1' THEN               -- Asynchronous clear
      ff  <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      ff(6) <= ff(3);
      ff(5) <= ff(2);
      ff(4) <= ff(1);
      ff(3) <= ff(5) XNOR ff(6);
      ff(2) <= ff(4) XNOR ff(5);
      ff(1) <= ff(3) XNOR ff(4);
    END IF;
  END PROCESS ;
  
  y <= ff;   -- Connect to I/O cell
  
END fpga;
