--*********************************************************
-- IEEE STD 1076-1993 VHDL file: lpm_add_sub.vhd
-- Author-EMAIL: Uwe.Meyer-Baese@ieee.org
--*********************************************************
-- N bit addition/subtraction

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY lib_add_sub IS
    GENERIC  (LPM_WIDTH : INTEGER;
              LPM_DIRECTION :  string := "ADD");
  PORT(dataa : IN  STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0);
       datab : IN  STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0);  
       result: OUT STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0));
END;   

ARCHITECTURE fpga OF lib_add_sub IS

BEGIN

  PROCESS(dataa, datab)
  BEGIN 
    IF LPM_DIRECTION = "SUB" THEN
      result <= dataa - datab;
    ELSE
      result <= dataa + datab;
    END IF; 
  END PROCESS;
   
END;
