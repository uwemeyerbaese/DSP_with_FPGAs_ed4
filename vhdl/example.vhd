PACKAGE n_bit_int IS    -- User defined type
  SUBTYPE S8 IS INTEGER RANGE -128 TO 127;
END n_bit_int;
LIBRARY work; USE work.n_bit_int.ALL;

LIBRARY ieee;                  -- Using predefined packages
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY example IS                         ------> Interface
  GENERIC (WIDTH : INTEGER := 8);   -- Bit width 
  PORT (clk   :  IN STD_LOGIC;    -- System clock
        reset : IN  STD_LOGIC;    -- Asynchronous reset
        a, b, op1  : IN STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
                                  -- SLV type inputs
        sum   :  OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
                                  -- SLV type output 
        c, d  :  OUT S8);         -- Integer output
END example;
-- --------------------------------------------------------
ARCHITECTURE fpga OF example IS
  COMPONENT lib_add_sub
    GENERIC  (LPM_WIDTH : INTEGER;
              LPM_DIRECTION :  string := "ADD");
  PORT(dataa : IN  STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0);
       datab : IN  STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0);  
       result: OUT STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0));
  END COMPONENT; 

  COMPONENT lib_ff 
  GENERIC (LPM_WIDTH : INTEGER); 
  PORT (clock : IN  STD_LOGIC;
        data  : IN  STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0); 
        q     : OUT STD_LOGIC_VECTOR(LPM_WIDTH-1 DOWNTO 0));
  END COMPONENT;   
  
  SIGNAL  a_i, b_i   :  S8 := 0;    -- Auxiliary signals
  SIGNAL  op2, op3   :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
BEGIN

  -- Conversion int -> logic vector
  op2 <= b;   

  add1: lib_add_sub         ------> Component instantiation
    GENERIC MAP (LPM_WIDTH => WIDTH,
                 LPM_DIRECTION => "ADD")  
    PORT MAP (dataa => op1, 
              datab => op2,
              result => op3);
  reg1: lib_ff
    GENERIC MAP (LPM_WIDTH => WIDTH )  
    PORT MAP (data => op3, 
              q => sum,
              clock => clk);
   
  c <= a_i + b_i;      ------> Data flow style (concurrent)
  a_i <= CONV_INTEGER(a); -- Order of statement does not
  b_i <= CONV_INTEGER(b); -- matter in concurrent code
  
  P1: PROCESS(clk, reset) ----> Behavioral/sequential style
  VARIABLE  s :  S8 := 0;    -- Auxiliary variable
  BEGIN
    IF reset = '1' THEN               -- Asynchronous clear
      s := 0; d <= 0;
    ELSIF rising_edge(clk) THEN -- pos. edge triggered FFs
      s := s + a_i;       ----> Sequential statement
      -- d <= s;          -- "d" at this line: b_i would
      s := s + b_i;       -- not be added to output. 
      d <= s;             -- Ordering of statements matters
    END IF;
  END PROCESS P1;
  
END fpga;
