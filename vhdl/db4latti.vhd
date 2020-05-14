PACKAGE n_bits_int IS             -- User defined types
  SUBTYPE S8 IS INTEGER RANGE -128 TO 127;
  SUBTYPE S9 IS INTEGER RANGE -2**8 TO 2**8-1;
  SUBTYPE S17 IS INTEGER RANGE -2**16 TO 2**16-1;
  TYPE A0_3S17 IS ARRAY (0 TO 3) OF S17;
END n_bits_int;

LIBRARY work;
USE work.n_bits_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
-- --------------------------------------------------------
ENTITY db4latti IS                   ------> Interface
  PORT (clk       : IN  STD_LOGIC;   -- System clock
        reset     : IN  STD_LOGIC;   -- Asynchronous reset
        clk2      : OUT STD_LOGIC;   -- Clock divider
        x_in      : IN  S8;          -- System input
        x_e, x_o  : OUT S17;         -- Even/odd x input
        g, h      : OUT S9);         -- g/h filter output
END db4latti;
-- --------------------------------------------------------
ARCHITECTURE fpga OF db4latti IS

  TYPE STATE_TYPE IS (even, odd);
  SIGNAL state                 : STATE_TYPE;
  SIGNAL clk_div2              : STD_LOGIC;
  SIGNAL sx_up, sx_low, x_wait : S17 := 0;
  SIGNAL sxa0_up, sxa0_low     : S17 := 0;
  SIGNAL up0, up1, low0, low1  : S17 := 0;

BEGIN

  Multiplex: PROCESS (reset, clk) ----> Split into even and
  BEGIN                          -- odd samples at clk rate
    IF reset = '1' THEN          -- Asynchronous reset
      state <= even;
      sx_up <= 0; sx_low <= 0; 
      clk_div2 <= '0'; x_wait <= 0;
    ELSIF rising_edge(clk) THEN  
      CASE state IS
        WHEN even =>   
        -- Multiply with 256*s=124
          sx_up   <= 4 * (32 *   x_in - x_in);   
          sx_low  <= 4 * (32 * x_wait - x_wait);
          clk_div2 <= '1';
          state <= odd;
        WHEN odd => 
          x_wait <= x_in;
          clk_div2 <= '0';
          state <= even;
      END CASE;
    END IF;
  END PROCESS;

---------- Multipy a[0] = 1.7321
  sxa0_up  <= (2*sx_up  - sx_up /4) 
                                 - (sx_up /64 + sx_up/256);
  sxa0_low <= (2*sx_low - sx_low/4) 
                                - (sx_low/64 + sx_low/256);
---------- First stage -- FF in lower tree
  up0  <= sxa0_low + sx_up;
  LowerTreeFF: PROCESS(reset, clk, clk_div2) 
  BEGIN
    IF reset = '1' THEN          -- Asynchronous clear
     low0 <= 0; 
    ELSIF rising_edge(clk) THEN 
      IF clk_div2 = '1' THEN    
        low0 <= sx_low - sxa0_up;         
      END IF;
    END IF;
  END PROCESS;

---------- Second stage  a[1]=0.2679
  up1  <= (up0 - low0/4) - (low0/64 + low0/256);
  low1 <= (low0 + up0/4) + (up0/64  +  up0/256);

  x_e  <= sx_up;   -- Provide some extra test signals
  x_o  <= sx_low;
  clk2 <= clk_div2;

  OutputScale: PROCESS(reset, clk, clk_div2) 
  BEGIN
    IF reset = '1' THEN          -- Asynchronous clear
     g <= 0; h <= 0;
    ELSIF rising_edge(clk) THEN 
      IF clk_div2 = '1' THEN    
        g <=  up1 / 256; 
        h <= low1 / 256;
      END IF;
    END IF;
  END PROCESS;

END fpga;
