--*********************************************************
-- IEEE STD 1076-1987/1993 VHDL file: add2p.vhd
-- Author-EMAIL: Uwe.Meyer-Baese@ieee.org
--*********************************************************
-- 28-bit adder with two pipeline stages
-- Uses no components. 
                    
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
-- --------------------------------------------------------
ENTITY add2p IS
  GENERIC (WIDTH : INTEGER := 46; -- Total bit width
           WIDTH1  : INTEGER := 15;  -- Bit width of LSBs 
           WIDTH2  : INTEGER := 15;  -- Bit width of middle
           WIDTH12 : INTEGER := 30; -- Sum WIDTH1+WIDTH2
           WIDTH3  : INTEGER := 16);  -- Bit width of MSBs
  PORT (x, y : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
                                                 --  Inputs
        sum  : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);     
                                                  -- Result
        LSBs_carry, MSBs_carry : OUT STD_LOGIC;--Carry bits
        clk  : IN  STD_LOGIC); -- System clock
END add2p;
-- --------------------------------------------------------
ARCHITECTURE fpga OF add2p IS

  SIGNAL  l1, l2, v1, s1              -- LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH1-1 DOWNTO 0);
  SIGNAL  q1                         -- LSBs with carry 
                     : STD_LOGIC_VECTOR(WIDTH1 DOWNTO 0);
  SIGNAL  l3, l4, s2                 -- Middle bits
                     : STD_LOGIC_VECTOR(WIDTH2-1 DOWNTO 0);
  SIGNAL  q2, v2                  -- Middle bits with carry
                     : STD_LOGIC_VECTOR(WIDTH2 DOWNTO 0);
  SIGNAL  l5, l6, q3, v3, s3      -- MSBs of input
                     : STD_LOGIC_VECTOR(WIDTH3-1 DOWNTO 0);           
BEGIN

  PROCESS  -- Split in MSBs and LSBs and store in registers
  BEGIN
    WAIT UNTIL clk = '1';
    -- Split LSBs from input x,y
    l1 <= x(WIDTH1-1 DOWNTO 0);
    l2 <= y(WIDTH1-1 DOWNTO 0);
    -- Split middle bits from input x,y
    l3 <= x(WIDTH12-1 DOWNTO WIDTH1);
    l4 <= y(WIDTH12-1 DOWNTO WIDTH1);
    -- Split MSBs from input x,y
    l5 <= x(WIDTH-1 DOWNTO WIDTH12);
    l6 <= y(WIDTH-1 DOWNTO WIDTH12);
--------------- First stage of the adder  -----------------
    q1 <= ('0' & l1) + ('0' & l2);  -- Add LSBs of x and y
    q2 <= ('0' & l3) + ('0' & l4);  -- Add LSBs of x and y
    q3 <= l5 + l6;                  -- Add MSBs of x and y
-------------- Second stage of the adder ------------------
    v1 <= q1(WIDTH1-1 DOWNTO 0);           -- Save q1   
-- Add result from middle bits (x+y) and carry from LSBs
    v2 <= q1(WIDTH1) + ('0' & q2(WIDTH2-1 DOWNTO 0));
-- Add result from MSBs bits (x+y) and carry from middle
    v3 <= q2(WIDTH2) + q3;
---------------- Third stage of the adder -----------------
    s1 <= v1;                             -- Save v1
    s2 <= v2(WIDTH2-1 DOWNTO 0);          -- Save v2
-- Add result from MSBs bits (x+y) and 2. carry from middle
    s3 <= v2(WIDTH2) + v3;
  END PROCESS;  

  LSBs_Carry <= q1(WIDTH1); -- Provide some test signals
  MSBs_Carry <= v2(WIDTH2);

  -- Build a single output word
  -- of WIDTH = WIDTH1 + WIDHT2 + WIDTH3
  sum <= s3 & s2 & s1;    -- Connect sum to output pins

END fpga;
