LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
-- --------------------------------------------------------
ENTITY add1p IS
  GENERIC (WIDTH  : INTEGER := 31; -- Total bit width
           WIDTH1 : INTEGER := 15;  -- Bit width of LSBs 
           WIDTH2 : INTEGER := 16);  -- Bit width of MSBs
  PORT (x,y : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  
                                                  -- Inputs
        sum : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  
                                                  -- Result
        LSBs_carry : OUT STD_LOGIC; -- Test port
        clk : IN  STD_LOGIC);  -- System clock
END add1p;
-- --------------------------------------------------------
ARCHITECTURE fpga OF add1p IS

  SIGNAL l1, l2, s1                   -- LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH1-1 DOWNTO 0); 
  SIGNAL r1                           -- LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH1 DOWNTO 0); 
  SIGNAL l3, l4, r2, s2                  -- MSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH2-1 DOWNTO 0);                       

BEGIN 

  PROCESS -- Split in MSBs and LSBs and store in registers
  BEGIN
   WAIT UNTIL clk = '1';
   -- Split LSBs from input x,y
      l1 <= x(WIDTH1-1 DOWNTO 0);
      l2 <= y(WIDTH1-1 DOWNTO 0);
    -- Split MSBs from input x,y
      l3 <= x(WIDTH-1 DOWNTO WIDTH1);
      l4 <= y(WIDTH-1 DOWNTO WIDTH1);
-------------- First stage of the adder  ------------------
     r1 <= ('0' & l1) + ('0' & l2);
     r2 <= l3 + l4;
------------ Second stage of the adder --------------------
     s1 <= r1(WIDTH1-1 DOWNTO 0);
  -- Add result von MSBs (x+y) and carry from LSBs
     s2 <= r1(WIDTH1) + r2;
  END PROCESS;
  LSBs_Carry <= r1(WIDTH1); -- Add a test signal

-- Build a single output word of WIDTH=WIDTH1+WIDHT2
  sum <= s2 & s1 ;    -- Connect s to output pins

END fpga;
