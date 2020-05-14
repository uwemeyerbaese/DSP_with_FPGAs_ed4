LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY case5p IS
       PORT ( clk       : IN  STD_LOGIC;
              table_in  : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
              table_out : OUT INTEGER RANGE 0 TO 25);
END case5p;

ARCHITECTURE LEs OF case5p IS

  SIGNAL lsbs : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL msbs0 : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL table0out00, table0out01 : INTEGER RANGE 0 TO 25;

BEGIN

-- These are the distributed arithmetic CASE tables for
-- the 5 coefficients: 1, 3, 5, 7, 9  
-- automatically generated with dagen.exe -- DO NOT EDIT!

  PROCESS
  BEGIN
    WAIT UNTIL clk = '1';
    lsbs(0) <= table_in(0);
    lsbs(1) <= table_in(1);
    lsbs(2) <= table_in(2);
    lsbs(3) <= table_in(3);
    msbs0(0) <= table_in(4);
    msbs0(1) <= msbs0(0);
  END PROCESS;

  PROCESS     -- This is the final DA MPX stage.
  BEGIN       -- Automatically generated with dagen.exe
    WAIT UNTIL clk = '1';
    CASE msbs0(1) IS
      WHEN  '0' =>    table_out <=  table0out00;
      WHEN  '1' =>    table_out <=  table0out01;
      WHEN   OTHERS  =>    table_out <=  0;
    END CASE;
  END PROCESS;

  PROCESS     -- This is the DA CASE table 00 out of 1.
  BEGIN       -- Automatically generated with dagen.exe
    WAIT UNTIL clk = '1';
    CASE lsbs IS 
      WHEN  "0000" =>    table0out00 <=  0;
      WHEN  "0001" =>    table0out00 <=  1;
      WHEN  "0010" =>    table0out00 <=  3;
      WHEN  "0011" =>    table0out00 <=  4;
      WHEN  "0100" =>    table0out00 <=  5;
      WHEN  "0101" =>    table0out00 <=  6;
      WHEN  "0110" =>    table0out00 <=  8;
      WHEN  "0111" =>    table0out00 <=  9;
      WHEN  "1000" =>    table0out00 <=  7;
      WHEN  "1001" =>    table0out00 <=  8;
      WHEN  "1010" =>    table0out00 <=  10;
      WHEN  "1011" =>    table0out00 <=  11;
      WHEN  "1100" =>    table0out00 <=  12;
      WHEN  "1101" =>    table0out00 <=  13;
      WHEN  "1110" =>    table0out00 <=  15;
      WHEN  "1111" =>    table0out00 <=  16;
      WHEN   OTHERS  =>    table0out00 <=  0;
    END CASE;
  END PROCESS;

  PROCESS     -- This is the DA CASE table 01 out of 1.
  BEGIN       -- Automatically generated with dagen.exe 
    WAIT UNTIL clk = '1';
    CASE lsbs IS 
      WHEN  "0000" =>    table0out01 <=  9;
      WHEN  "0001" =>    table0out01 <=  10;
      WHEN  "0010" =>    table0out01 <=  12;
      WHEN  "0011" =>    table0out01 <=  13;
      WHEN  "0100" =>    table0out01 <=  14;
      WHEN  "0101" =>    table0out01 <=  15;
      WHEN  "0110" =>    table0out01 <=  17;
      WHEN  "0111" =>    table0out01 <=  18;
      WHEN  "1000" =>    table0out01 <=  16;
      WHEN  "1001" =>    table0out01 <=  17;
      WHEN  "1010" =>    table0out01 <=  19;
      WHEN  "1011" =>    table0out01 <=  20;
      WHEN  "1100" =>    table0out01 <=  21;
      WHEN  "1101" =>    table0out01 <=  22;
      WHEN  "1110" =>    table0out01 <=  24;
      WHEN  "1111" =>    table0out01 <=  25;
      WHEN   OTHERS  =>    table0out01 <=  0;
    END CASE;
  END PROCESS;
END LEs;
