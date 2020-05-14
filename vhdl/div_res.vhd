-- Restoring Division
LIBRARY ieee; USE ieee.std_logic_1164.ALL;
PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE SLVN IS STD_LOGIC_VECTOR(7 DOWNTO 0);
  SUBTYPE SLVD IS STD_LOGIC_VECTOR(5 DOWNTO 0);  
END n_bits_int;
LIBRARY work; USE work.n_bits_int.ALL;

LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
-- --------------------------------------------------------
ENTITY div_res IS                      ------> Interface
  GENERIC(WN : INTEGER := 8;
          WD : INTEGER := 6;
          PO2WND : INTEGER := 8192; -- 2**(WN+WD)
          PO2WN1 : INTEGER := 128;  -- 2**(WN-1)
          PO2WN : INTEGER := 255);  -- 2**WN-1
  PORT(clk   : IN  STD_LOGIC;   -- System clock
       reset : IN  STD_LOGIC;   -- Asynchronous reset
       n_in    : IN  SLVN;      -- Nominator
       d_in    : IN  SLVD;      -- Denumerator 
       r_out   : OUT SLVD;      -- Remainder 
       q_out   : OUT SLVN);     -- Quotient
END div_res;
-- --------------------------------------------------------
ARCHITECTURE fpga OF div_res IS

  SUBTYPE S14 IS INTEGER RANGE -PO2WND TO PO2WND-1;
  SUBTYPE U8 IS INTEGER RANGE 0 TO PO2WN;
  SUBTYPE U4 IS INTEGER RANGE 0 TO WN;

  TYPE STATE_TYPE IS (ini, sub, restore, done);
  SIGNAL state : STATE_TYPE;

BEGIN
-- Bit width:  WN         WD           WN            WD
--         Nominator / Denumerator = Quotient and Remainder
-- OR:       Nominator = Quotient * Denumerator + Remainder

  States: PROCESS(reset, clk)-- Divider in behavioral style
    VARIABLE  r, d : S14 :=0;  -- N+D bit width
    VARIABLE  q : U8;
    VARIABLE count  : U4;
  BEGIN
    IF reset = '1' THEN               -- asynchronous reset
      state <= ini; q_out <= (OTHERS => '0');
      r_out <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN  
    CASE state IS
      WHEN ini =>          -- Initialization step 
        state <= sub;
        count := 0;
        q := 0;           -- Reset quotient register
        d := PO2WN1  * CONV_INTEGER(d_in); -- Load denumer.        
        r := CONV_INTEGER(n_in); -- Remainder = nominator
      WHEN sub =>          -- Processing step
          r := r - d;      -- Subtract denumerator
          state <= restore;
      WHEN restore =>      -- Restoring step
        IF r < 0 THEN     
          r := r + d;     -- Restore previous remainder
          q := q * 2;     -- LSB = 0 and SLL
        ELSE
          q := 2 * q + 1; -- LSB = 1 and SLL
        END IF;
        count := count + 1;
        d := d / 2;
        IF count = WN THEN -- Division ready ?
          state <= done;
        ELSE
          state <= sub;
        END IF;
      WHEN done =>                   -- Output of result
        q_out <= CONV_STD_LOGIC_VECTOR(q, WN); 
        r_out <= CONV_STD_LOGIC_VECTOR(r, WD); 
        state <= ini;               -- Start next division
    END CASE;
    END IF;
  END PROCESS States;
  
END fpga;
