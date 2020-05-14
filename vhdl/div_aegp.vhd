-- Convergence division after Anderson, Earle, Goldschmidt,
LIBRARY ieee; USE ieee.std_logic_1164.ALL;    -- and Powers

PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE U3 IS INTEGER RANGE 0 TO 7;
  SUBTYPE U10 IS INTEGER RANGE 0 TO 1023;  
  SUBTYPE SLVN IS STD_LOGIC_VECTOR(8 DOWNTO 0);
  SUBTYPE SLVD IS STD_LOGIC_VECTOR(8 DOWNTO 0);  
END n_bits_int;

LIBRARY work; 
USE work.n_bits_int.ALL;

LIBRARY ieee; 
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
-- --------------------------------------------------------
ENTITY div_aegp IS                      ------> Interface
  GENERIC(WN : INTEGER := 9; -- 8 bit plus one integer bit
          WD : INTEGER := 9; 
          STEPS : INTEGER := 2;
          TWO : INTEGER := 512;       -- 2**(WN+1)
          PO2WN  : INTEGER := 256;    -- 2**(WN-1)
          PO2WN2 : INTEGER := 1023);  -- 2**(WN+1)-1
  PORT (clk   : IN  STD_LOGIC;   -- System clock
        reset : IN  STD_LOGIC;   -- Asynchronous reset
        n_in  : IN  SLVN;        -- Nominator
        d_in  : IN  SLVD;        -- Denumerator 
        q_out : OUT SLVD);       -- Quotient
END div_aegp;
-- --------------------------------------------------------
ARCHITECTURE fpga OF div_aegp IS

  TYPE STATE_TYPE IS (ini, run, done);
  SIGNAL state    : STATE_TYPE;

BEGIN
-- Bit width:  WN         WD        WN             WD
--         Nominator / Denumerator = Quotient and Remainder
-- OR:       Nominator = Quotient * Denumerator + Remainder

  States: PROCESS(reset, clk)-- Divider in behavioral style
    VARIABLE  x, t, f : U10 := 0; -- WN+1 bits
    VARIABLE count  : INTEGER RANGE 0 TO STEPS;
  BEGIN
    IF reset = '1' THEN               -- Asynchronous reset
      state <= ini;
      q_out <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN    
    CASE state IS
      WHEN ini =>              -- Initialization step 
        state <= run;
        count := 0;
        t := CONV_INTEGER(d_in); -- Load denominator
        x := CONV_INTEGER(n_in); -- Load nominator
      WHEN run =>          -- Processing step
        f := TWO - t;
        x := x * f / PO2WN;
        t := t * f / PO2WN;
        count := count + 1;
        IF count = STEPS THEN -- Division ready ?
          state <= done;
        ELSE
          state <= run;
        END IF;
      WHEN done =>                   -- Output of results
        q_out <= CONV_STD_LOGIC_VECTOR(x, WN); 
        state <= ini;               -- start next division
    END CASE;
    END IF;
  END PROCESS States;
  
END fpga;
