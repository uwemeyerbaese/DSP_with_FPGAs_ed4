-- Title: Floating-Point Unit 
-- Description: This is an arithmetic unit to 
-- implement basic 32-bit FP operations.
-- It uses VHDL2008 operations that are also
-- available for 1076-1993 as library function from
-- www.eda.org/fphdl
LIBRARY ieee; USE ieee.std_logic_1164.ALL;
PACKAGE n_bit_int IS               -- User defined types
  SUBTYPE SLV4 IS STD_LOGIC_VECTOR(3 DOWNTO 0);
  SUBTYPE SLV32 IS STD_LOGIC_VECTOR(31 DOWNTO 0);
END n_bit_int;
LIBRARY work; USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

LIBRARY ieee_proposed;
USE ieee_proposed.fixed_float_types.ALL;
USE ieee_proposed.fixed_pkg.ALL;
USE ieee_proposed.float_pkg.ALL;
-- --------------------------------------------------------
ENTITY fpu IS 
  PORT(sel    : IN  SLV4;    -- FP operation number
       dataa  : IN  SLV32;   -- First input
       datab  : IN  SLV32;   -- Second input
       n      : IN  INTEGER; -- Scale factor 2**n
       result : OUT SLV32);  -- System output
END;
-- --------------------------------------------------------
ARCHITECTURE fpga OF fpu IS

-- OP Code of instructions:
--  CONSTANT fix2fp : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"0";
--  CONSTANT fp2fix : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"1";
--  CONSTANT add    : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"2";
--  CONSTANT sub    : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"3";
--  CONSTANT mul    : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"4";
--  CONSTANT div    : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"5";
--  CONSTANT rec    : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"6";
--  CONSTANT scale  : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"7";
  
  TYPE OP_TYPE IS (fix2fp, fp2fix, add, sub, mul, div, rec,
                                                    scale);
  SIGNAL op : OP_TYPE;
  SIGNAL a, b, r : FLOAT32;
  SIGNAL sfixeda, sfixedr : SFIXED(15 DOWNTO -16);

BEGIN

-- Redefine SLV bit as FP number
  a <= TO_FLOAT(dataa, a);
  b <= TO_FLOAT(datab, b);
-- Redefine SLV bit as 16.16 sfixed number
  sfixeda <= TO_SFIXED(dataa, sfixeda);
 
  P1: PROCESS (a, b, sfixedr, sfixeda, sel, r, n, op)
  BEGIN   
    r <= (OTHERS => '0'); sfixedr <= (OTHERS => '0');
    CASE CONV_INTEGER(sel) IS
      WHEN 0 =>   r <= TO_FLOAT(sfixeda, r); op <= fix2fp;
      WHEN 1 =>   sfixedr <= TO_SFIXED(a, sfixedr); 
                  op <= fp2fix;
      WHEN 2 =>   r <= a + b; op <= add;
      WHEN 3 =>   r <= a - b; op <= sub;
      WHEN 4 =>   r <= a * b; op <= mul;
      WHEN 5 =>   r <= a / b; op <= div;
      WHEN 6 =>   r <= reciprocal(arg=> a); op <= rec;
      WHEN 7 =>   r <= scalb(y=>a, n=>n); op <= scale;
      WHEN OTHERS =>   op <= scale; 
    END CASE;
-- Interpret FP or 16.16 sfixed bits as SLV bit vector
    IF op = fp2fix THEN
      result <= TO_SLV(sfixedr);
    ELSE
      result <= TO_SLV(r);
    END IF;
  END PROCESS P1;

END fpga;
