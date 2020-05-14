PACKAGE n_bit_int IS    -- User defined types
  SUBTYPE S8 IS INTEGER RANGE -128 TO 127;
  SUBTYPE S9 IS INTEGER RANGE -256 TO 256;
  TYPE A0_3S9 IS ARRAY (0 TO 3) OF S9;
END n_bit_int;

LIBRARY work;
USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- --------------------------------------------------------
ENTITY cordic IS                      ------> Interface
  PORT (clk   : IN  STD_LOGIC; -- System clock
        reset : IN  STD_LOGIC; -- Asynchronous reset
        x_in  : IN  S8;  -- System real or x input
        y_in  : IN  S8;  -- System imaginary or y input
        r     : OUT S9;  -- Radius result
        phi   : OUT S9;  -- Phase result
        eps   : OUT S9); -- Error of results
END cordic;
-- --------------------------------------------------------
ARCHITECTURE fpga OF cordic IS
    --SIGNAL  x, y, z  :   A0_3S9; -- Array of Bytes
BEGIN
 
  P1: PROCESS(x_in, y_in, reset, clk) --> Behavioral Style
    VARIABLE  x, y, z  :   A0_3S9; -- Array of Bytes
  BEGIN
  IF reset = '1' THEN -- Asynchronous clear
    FOR K IN 0 TO 3 LOOP
      x(k) := 0; y(k) := 0; z(k) := 0;
    END LOOP;
    r <= 0; eps <= 0; phi <= 0;
  ELSIF rising_edge(clk) THEN                 
    r <= x(3);            -- Compute last value first in
    phi <= z(3);          -- sequential VHDL statements !!
    eps <= y(3);

    IF y(2) >= 0 THEN            -- Rotate 14 degrees
      x(3) := x(2) + y(2) /4;
      y(3) := y(2) - x(2) /4;
      z(3) := z(2) + 14;
    ELSE
      x(3) := x(2) - y(2) /4;
      y(3) := y(2) + x(2) /4;
      z(3) := z(2) - 14;
    END IF;

    IF y(1) >= 0 THEN            -- Rotate 26 degrees
      x(2) := x(1) + y(1) /2;
      y(2) := y(1) - x(1) /2;
      z(2) := z(1) + 26;
    ELSE
      x(2) := x(1) - y(1) /2;
      y(2) := y(1) + x(1) /2;
      z(2) := z(1) - 26;
    END IF;

    IF y(0) >= 0 THEN            -- Rotate  45 degrees
      x(1) := x(0) + y(0);
      y(1) := y(0) - x(0);
      z(1) := z(0) + 45;
    ELSE
      x(1) := x(0) - y(0);
      y(1) := y(0) + x(0);
      z(1) := z(0) - 45;
    END IF;

-- Test for x_in < 0 rotate 0,+90, or -90 degrees
    IF x_in >= 0 THEN 
      x(0) := x_in;       -- Input in register 0
      y(0) := y_in;
      z(0) := 0;
    ELSIF y_in >= 0 THEN
      x(0) := y_in;
      y(0) := - x_in;
      z(0) := 90;
    ELSE
      x(0) := - y_in;
      y(0) := x_in;
      z(0) := -90;
    END IF;
    END IF;
  END PROCESS;
  
END fpga;
