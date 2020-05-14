PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE S8 IS INTEGER RANGE -128 TO 127;
  SUBTYPE S9 IS INTEGER RANGE -2**8 TO 2**8-1;
  SUBTYPE S17 IS INTEGER RANGE -2**16 TO 2**16-1;
  TYPE A0_3S17 IS ARRAY (0 TO 3) of S17;
END n_bits_int;

LIBRARY work;
USE work.n_bits_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY db4poly IS                         ------> Interface
  PORT (clk       : IN  STD_LOGIC; -- System clock
        reset     : IN  STD_LOGIC; -- Asynchron reset
        x_in      : IN  S8;        -- System input
        clk2      : OUT STD_LOGIC; -- Clock divided by 2
        x_e, x_o  : OUT S17;       -- Even/odd x_in
        g0, g1    : OUT S17;       -- Poly filter 0/1
        y_out     : OUT S9);       -- System output
END db4poly;
-- --------------------------------------------------------
ARCHITECTURE fpga OF db4poly IS

  TYPE STATE_TYPE IS (even, odd);
  SIGNAL state                 : STATE_TYPE;
  SIGNAL x_odd, x_even, x_wait : S8 := 0;
  SIGNAL clk_div2              : STD_LOGIC;
  -- Arrays for multiplier and taps:
  SIGNAL r  : A0_3S17 := (0,0,0,0); 
  SIGNAL x33, x99, x107     : S17 := 0;
  SIGNAL y     : S17;

BEGIN

  Multiplex: PROCESS(reset, clk) ----> Split into even and
  BEGIN                         -- odd samples at clk rate
    IF reset = '1' THEN         -- Asynchronous reset
      state <= even;
      clk_div2 <= '0'; x_even <= 0; x_odd <= 0; x_wait <= 0;
    ELSIF rising_edge(clk) THEN  
      CASE state IS
        WHEN even =>   
          x_even <= x_in; 
          x_odd  <= x_wait;
          clk_div2 <= '1';
          state <= odd;
        WHEN odd => 
          x_wait <= x_in;
          clk_div2 <= '0';
          state <= even;
      END CASE;
    END IF;
  END PROCESS Multiplex;

  AddPolyphase: PROCESS (reset, clk_div2, x_odd, x_even,
                                            x33, x99, x107)
  VARIABLE m  : A0_3S17; 
  BEGIN
-- Compute auxiliary multiplications of the filter
    x33  <= x_odd * 32 + x_odd;            
    x99  <= x33 * 2 + x33;                  
    x107 <= x99 + 8 * x_odd;
-- Compute all coefficients for the transposed filter
    m(0) := 4 * (32 * x_even - x_even);       -- m[0] = 127
    m(1) := 2 * x107;                         -- m[1] = 214
    m(2) := 8 * (8 * x_even - x_even) + x_even;-- m[2] = 57
    m(3) := x33;                              -- m[3] = -33

    IF reset = '1' THEN -- Asynchronous clear all registers
      FOR k IN 0 TO 3 LOOP
        r(k) <= 0; 
      END LOOP;
      y <= 0;
------> Compute the filters and infer registers      
    ELSIF falling_edge(clk_div2) THEN  
------------ Compute filter G0             
      r(0) <=  r(2) + m(0);    -- g[0] = 127
      r(2) <=  m(2);           -- g[2] = 57
------------ Compute filter G1
      r(1) <=  -r(3) + m(1);   -- g[1] = 214
      r(3) <=  m(3);           -- g[3] = -33
------------ Add the polyphase components 
      y <= r(0) + r(1); 
    END IF;
  END PROCESS AddPolyphase;

  x_e <= x_even; -- Provide some test signal as outputs
  x_o <= x_odd;
  clk2 <= clk_div2;
  g0 <= r(0);
  g1 <= r(1);

  y_out <= y / 256; -- Connect to output

END fpga;
