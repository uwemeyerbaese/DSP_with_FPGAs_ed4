--*********************************************************
-- IEEE STD 1076-1987/1993 VHDL file: lpm_ff.vhd
-- Author-EMAIL: Uwe.Meyer-Baese@ieee.org
--*********************************************************
-- N bit register
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY lib_ff IS
  GENERIC (LPM_WIDTH : INTEGER); 
  PORT (clock : IN  STD_LOGIC;
        data  : IN  STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0); 
        q: OUT STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0));
END;

ARCHITECTURE fpga OF lib_ff IS
BEGIN
   
  P1: PROCESS
  BEGIN
    WAIT UNTIL clock = '1';
    q <= data;
  END PROCESS;
    
END;
