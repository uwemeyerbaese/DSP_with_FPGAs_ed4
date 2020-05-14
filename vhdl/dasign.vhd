LIBRARY ieee; USE ieee.std_logic_1164.ALL;

PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE U3 IS INTEGER RANGE 0 TO 7;
  SUBTYPE S4 IS INTEGER RANGE -8 TO 7;
  SUBTYPE S7 IS INTEGER RANGE -64 TO 63;  
  SUBTYPE SLV4 IS STD_LOGIC_VECTOR(3 DOWNTO 0);
END n_bits_int;

LIBRARY work; 
USE work.n_bits_int.ALL;

LIBRARY ieee;               -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY dasign IS                      ------> Interface
  PORT (clk   : IN STD_LOGIC;   -- System clock
        reset : IN STD_LOGIC;   -- Asynchronous reset
        x0_in : IN SLV4;        -- First system input
        x1_in : IN SLV4;        -- Second system input
        x2_in : IN SLV4;        -- Third system input
        lut   : OUT S4;         -- DA look-up table
        y     : OUT S7);        -- System output
END dasign;

ARCHITECTURE fpga OF dasign IS

  COMPONENT case3s      -- User defined components
    PORT ( table_in : IN  STD_LOGIC_VECTOR(2 DOWNTO 0); 
          table_out : OUT INTEGER RANGE -2 TO 4);
  END COMPONENT;

  TYPE STATE_TYPE IS (ini, run);
  SIGNAL state      : STATE_TYPE;
  SIGNAL table_in   : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL x0, x1, x2 : SLV4;
  SIGNAL table_out  : INTEGER RANGE -2 TO 4;
  
BEGIN

  table_in(0) <= x0(0); -- Connect register to look-up table
  table_in(1) <= x1(0);
  table_in(2) <= x2(0);

  P1:PROCESS (reset, clk)    ------> DA in behavioral style
    VARIABLE  p : S7;     -- Temporary product register
    VARIABLE count : U3;  -- Counter for shifts
  BEGIN                                    
    IF reset = '1' THEN               -- asynchronous reset
      state <= ini;
      x0 <= (OTHERS => '0');
      x1 <= (OTHERS => '0');
      x2 <= (OTHERS => '0');      
      p := 0; y <= 0;
    ELSIF rising_edge(clk) THEN  
    CASE state IS
      WHEN ini =>        -- Initialization step 
        state <= run;
        count := 0;
        p := 0;           
        x0 <= x0_in;
        x1 <= x1_in;
        x2 <= x2_in;
      WHEN run =>          -- Processing step
        IF count = 4 THEN -- Is sum of product done?
          y <= p;      -- Output of result to y and
          state <= ini; -- start next sum of product
        ELSE
          IF count = 3 THEN           -- Subtract for last 
          p := p / 2 - table_out * 8; -- accumulator step
          ELSE                         
          p := p / 2 + table_out * 8;  -- Accumulation for
          END IF;                      -- all other steps
            FOR k IN 0 TO 2 LOOP    -- Shift bits
              x0(k) <= x0(k+1);
              x1(k) <= x1(k+1);
              x2(k) <= x2(k+1);
            END LOOP;
          count := count + 1;
          state <= run;
        END IF;
    END CASE;
    END IF;
  END PROCESS;

  LC_Table0: case3s
    PORT MAP(table_in => table_in, table_out => table_out);
    
  lut <= table_out; -- Extra test signal

END fpga;
