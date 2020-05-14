--*********************************************************
-- IEEE STD 1076-1987/1993 VHDL file: add3p.vhd
-- Author-EMAIL: Uwe.Meyer-Baese@ieee.org
--*********************************************************
-- 37-bit adder with three pipeline stages
-- Uses no components.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
-- --------------------------------------------------------
ENTITY add3p IS
  GENERIC (WIDTH   : INTEGER := 61; -- Total bit width
           WIDTH0  : INTEGER := 15;  -- Bit width of LSBs 
           WIDTH1  : INTEGER := 15;  -- Bit width of 2. LSBs
           WIDTH01 : INTEGER := 30; -- Sum WIDTH0+WIDTH1
           WIDTH2  : INTEGER := 15;  -- Bit width of 2. MSBs
           WIDTH012 :INTEGER := 45; -- WIDTH0+WIDTH1+WIDTH2
           WIDTH3  : INTEGER := 16);  -- Bit width of MSBs
  PORT ( x,y :  IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);     
                                                 --  Inputs
         sum :  OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);     
                                                  -- Result
      LSBs_Carry, Middle_Carry, MSBs_Carry : OUT STD_LOGIC;
         clk :  IN  STD_LOGIC);
END add3p;
-- --------------------------------------------------------
ARCHITECTURE fpga OF add3p IS

  SIGNAL  l0, l1, r0, v0, s0          -- LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH0-1 DOWNTO 0);
  SIGNAL  q0          -- LSBs of inputs with carry
                     : STD_LOGIC_VECTOR(WIDTH0 DOWNTO 0);

  SIGNAL  l2, l3, r1, s1       -- 2. LSBs of inputs
                     : STD_LOGIC_VECTOR(WIDTH1-1 DOWNTO 0);
  SIGNAL  v1, q1      -- 2. LSBs with carry
                     : STD_LOGIC_VECTOR(WIDTH1 DOWNTO 0); 
  SIGNAL  l4, l5, s2, h7        -- 2. MSBs bits
                     : STD_LOGIC_VECTOR(WIDTH2-1 DOWNTO 0); 
  SIGNAL  q2, v2, r2        -- 2. MSBs bits with carry
                     : STD_LOGIC_VECTOR(WIDTH2 DOWNTO 0); 
  SIGNAL  l6, l7, q3, v3, r3, s3, h8       -- MSBs of input
                     : STD_LOGIC_VECTOR(WIDTH3-1 DOWNTO 0);                                                  
                                                
BEGIN

  P1: PROCESS  -- Split in MSBs and LSBs and store in registers
  BEGIN
    WAIT UNTIL clk = '1';
    -- Split LSBs from input x,y
    l0 <= x(WIDTH0-1 DOWNTO 0);
    l1 <= y(WIDTH0-1 DOWNTO 0);
    -- Split 2. LSBs from input x,y
    l2 <= x(WIDTH01-1 DOWNTO WIDTH0);
    l3 <= y(WIDTH01-1 DOWNTO WIDTH0);
    -- Split 2. MSBs from input x,y
    l4 <= x(WIDTH012-1 DOWNTO WIDTH01);
    l5 <= y(WIDTH012-1 DOWNTO WIDTH01);
    -- Split MSBs from input x,y
    l6 <= x(WIDTH-1 DOWNTO WIDTH012);
    l7 <= y(WIDTH-1 DOWNTO WIDTH012);
---------------- First stage of the adder  ----------------
    q0 <= ('0' & l0) + ('0' & l1);   -- Add LSBs of x and y
    q1 <= ('0' & l2) + ('0' & l3);  -- Add 2. LSBs of x / y
    q2 <= ('0' & l4) + ('0' & l5); -- Add 2. MSBs x and y
    q3 <= l6 + l7;                   -- Add MSBs of x and y
--------------- Second stage of the adder -----------------
    v0 <= q0(WIDTH0-1 DOWNTO 0);           -- Save q0   
-- Add result from 2. LSBs (x+y) and carry from LSBs 
    v1 <= q0(WIDTH0) + ('0' & q1(WIDTH1-1 DOWNTO 0));
-- Add result from 2. MSBs (x+y) and carry from 2. LSBs  
    v2 <= q1(WIDTH1) + ('0' & q2(WIDTH2-1 DOWNTO 0));
-- Add result from MSBs (x+y) and carry from 2. MSBs 
    v3 <= q2(WIDTH2) + q3;
-------------- Third stage of the adder -------------------
    r0 <= v0;  -- Delay for LSBs
    r1 <= v1(WIDTH1-1 DOWNTO 0);  -- Delay for 2. LSBs
-- Add result from 2. MSBs (x+y) and carry from 2. LSBs 
    r2 <= v1(WIDTH1) + ('0' & v2(WIDTH2-1 DOWNTO 0));                                        
-- Add result from MSBs (x+y) and carry from 2. MSBs
    r3 <= v2(WIDTH2) + v3;
----------------- Fourth stage of the adder ----------------------
    s0 <= r0;  -- Delay for LSBs
    s1 <= r1;  -- Delay for 2. LSBs
    s2 <= r2(WIDTH2-1 DOWNTO 0);  -- Delay for 2. MSBs
-- Add result from MSBs (x+y) and carry from 2. MSBs 
    s3 <= r2(WIDTH2) + r3;    
   END PROCESS;

   LSBs_Carry <= q0(WIDTH1);  -- Provide some test signals
   Middle_Carry <= v1(WIDTH1);
   MSBs_Carry <= r2(WIDTH2);   

-- Build a single output word
-- of WIDTH = WIDTH0 + WIDTH1 + WIDTH2 + WIDTH3
  sum <= s3 & s2 & s1 & s0; -- Connect sum to output pins   

END fpga;
