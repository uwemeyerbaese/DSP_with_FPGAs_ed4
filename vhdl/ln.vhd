PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE S9 IS INTEGER RANGE -2**8 TO 2**8-1;
  SUBTYPE S18 IS INTEGER RANGE -2**17 TO 2**17-1;
  TYPE A0_5S18 IS ARRAY (0 TO 5) of S18;
END n_bits_int;

LIBRARY work;
USE work.n_bits_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY ln IS                          ------> Interface
  GENERIC (N : INTEGER := 5); -- Number of Coeffcients-1 
  PORT (clk      : IN  STD_LOGIC; -- System clock
        reset    : IN  STD_LOGIC; -- Asynchron reset
        x_in     : IN  S18;       -- System input
        f_out    : OUT S18:=0);   -- System output
END ln;
-- --------------------------------------------------------
ARCHITECTURE fpga OF ln IS

  SIGNAL x, f : S18:= 0; -- Auxilary wire
-- Polynomial coefficients for 16 bit precision: 
-- f(x) = (1  + 65481 x -32093 x^2 + 18601 x^3 
--                      -8517 x^4 + 1954 x^5)/65536
  CONSTANT p : A0_5S18 := 
         (1,65481,-32093,18601,-8517,1954);
  SIGNAL s : A0_5S18;
 
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
  SOP: PROCESS (x,s) 
  VARIABLE slv : STD_LOGIC_VECTOR(35 DOWNTO 0);
  BEGIN
-- Polynomial Approximation from Chebyshev coeffiecients
  s(N) <= p(N);
  FOR K IN N-1 DOWNTO 0 LOOP
    slv := CONV_STD_LOGIC_VECTOR(x,18) 
                        * CONV_STD_LOGIC_VECTOR(s(K+1),18);
    s(K) <= CONV_INTEGER(slv(33 downto 16)) + p(K); 
  END LOOP;       -- x*s/65536 problem 32 bits
  f  <= s(0);     -- make visiable outside
  END PROCESS SOP;
  
END fpga;
