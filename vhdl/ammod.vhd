PACKAGE n_bit_int IS    -- User defined types
  SUBTYPE S9 IS INTEGER RANGE -256 TO 255;
  TYPE A0_3S9 IS ARRAY (0 TO 3) OF S9;
END n_bit_int;

LIBRARY work; USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; USE ieee.std_logic_arith.ALL;
-- --------------------------------------------------------
ENTITY ammod IS                 ----------------> Interface
       PORT (clk    : IN  STD_LOGIC;  -- System clock
             reset  : IN  STD_LOGIC;  -- Asynchronous reset
             r_in   : IN  S9;  -- Radius input
             phi_in : IN  S9;  -- Phase input
             x_out  : OUT S9;  -- x or real part output
             y_out  : OUT S9;  -- y or imaginary part
             eps    : OUT S9); -- Error of results
END ammod;
-- --------------------------------------------------------
ARCHITECTURE fpga OF ammod IS

BEGIN
 
  PROCESS(clk, reset, r_in, phi_in) --> Behavioral style
    VARIABLE x, y, z : A0_3S9;  -- Register arrays
  BEGIN                           
  IF reset = '1' THEN -- Asynchronous clear
    FOR k IN 0 TO 3 LOOP
      x(k) := 0; y(k) := 0; z(k) := 0;
    END LOOP;
    x_out <= 0; eps <= 0; y_out <= 0;
  ELSIF rising_edge(clk) THEN    
  -- Compute last value first 
    x_out <= x(3);         -- in sequential statements !!
    eps   <= z(3);
    y_out <= y(3);

    IF z(2) >= 0 THEN                 -- Rotate 14 degrees
      x(3) := x(2) - y(2) /4;
      y(3) := y(2) + x(2) /4;
      z(3) := z(2) - 14;
    ELSE
      x(3) := x(2) + y(2) /4;
      y(3) := y(2) - x(2) /4;
      z(3) := z(2) + 14;
    END IF;

    IF z(1) >= 0 THEN                 -- Rotate 26 degrees
      x(2) := x(1) - y(1) /2;
      y(2) := y(1) + x(1) /2;
      z(2) := z(1) - 26;
    ELSE
      x(2) := x(1) + y(1) /2;
      y(2) := y(1) - x(1) /2;
      z(2) := z(1) + 26;
    END IF;

    IF z(0) >= 0 THEN                -- Rotate  45 degrees
      x(1) := x(0) - y(0);
      y(1) := y(0) + x(0);
      z(1) := z(0) - 45;
    ELSE
      x(1) := x(0) + y(0);
      y(1) := y(0) - x(0);
      z(1) := z(0) + 45;
    END IF;

    IF phi_in > 90    THEN     -- Test for |phi_in| > 90 
      x(0) := 0;               -- Rotate 90 degrees
      y(0) := r_in;            -- Input in register 0
      z(0) := phi_in - 90;
    ELSIF phi_in < -90 THEN
      x(0) := 0;
      y(0) := - r_in;
      z(0) := phi_in + 90;
    ELSE
      x(0) := r_in;
      y(0) := 0;
      z(0) := phi_in;
    END IF;
  END IF;
  END PROCESS;
  
END fpga;
