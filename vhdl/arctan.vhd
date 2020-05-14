PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE S9 IS INTEGER RANGE -2**8 TO 2**8-1;
  TYPE A1_5S9 IS ARRAY (1 TO 5) OF S9;
END n_bits_int;

LIBRARY work; 
USE work.n_bits_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; 
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY arctan IS                          ------> Interface
  PORT (clk      : IN  STD_LOGIC; -- System clock
        reset    : IN  STD_LOGIC; -- Asynchron reset
        x_in     : IN  S9;        -- System input
        d_o      : OUT A1_5S9;    -- Auxiliary recurrence
        f_out    : OUT S9);       -- System output
END arctan;
-- --------------------------------------------------------
ARCHITECTURE fpga OF arctan IS

  SIGNAL x, f : S9; -- Auxilary signals
  SIGNAL d : A1_5S9 := (0,0,0,0,0); -- Auxilary array
  -- Chebychev coefficients for 8-bit precision: 
  CONSTANT c1 : S9 := 212;
  CONSTANT c3 : S9 := -12;
  CONSTANT c5 : S9 := 1;

BEGIN

  STORE: PROCESS(reset, clk)   -----> I/O store in register
  BEGIN                    
    IF reset = '1' THEN -- Asynchronous clear
      x <= 0; f_out <= 0;
    ELSIF rising_edge(clk) THEN
      x <= x_in;
      f_out <= f;
    END IF;
  END PROCESS;

  --> Compute sum-of-products:
  SOP: PROCESS(x, d) 
  BEGIN
-- Clenshaw's recurrence formula
  d(5) <= c5; 
  d(4) <= x * d(5) / 128;
  d(3) <= x * d(4) / 128 - d(5) + c3;
  d(2) <= x * d(3) / 128 - d(4);
  d(1) <= x * d(2) / 128 - d(3) + c1;
  f  <= x * d(1) / 256 - d(2); -- last step is different
  END PROCESS SOP;
  
  d_o <= d;     -- Provide some test signals as outputs

END fpga;
