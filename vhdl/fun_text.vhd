--  A 32 bit function generator using accumulator and ROM
LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_arith.ALL;
USE ieee.STD_LOGIC_signed.ALL;
-- --------------------------------------------------------
ENTITY fun_text IS
  GENERIC ( WIDTH   : INTEGER := 32);    -- Bit width
  PORT (clk   : IN  STD_LOGIC; -- System clock
        reset : IN  STD_LOGIC; -- Asynchronous reset
        M     : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
                                   -- Accumulator increment
        acc   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
                                        -- Accumulator MSBs
        sin   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END fun_text;                         -- System sine output
-- --------------------------------------------------------
ARCHITECTURE fpga OF fun_text IS

  COMPONENT sine256x8
    PORT (clk : IN STD_LOGIC;
          addr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
          data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
  END COMPONENT;

  SIGNAL acc32 : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  SIGNAL msbs  : STD_LOGIC_VECTOR(7 DOWNTO 0);
                                       -- Auxiliary vectors
BEGIN
   
  PROCESS (reset, clk, acc32)
  BEGIN
    IF reset = '1' THEN
      acc32 <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      acc32 <= acc32 + M; -- Add M to acc32 and 
    END IF;               -- store in register
    
  END PROCESS;
  
  msbs <= acc32(31 DOWNTO 24); -- Select MSBs        
  acc <= msbs;

  -- Instantiate the ROM
  ROM: sine256x8 PORT MAP
                   (clk => clk, addr => msbs, data => sin);
            
END fpga;
