LIBRARY ieee; USE ieee.std_logic_1164.ALL;

PACKAGE n_bit_int IS               -- User defined type
  SUBTYPE U5 IS INTEGER RANGE 0 TO 32;
  SUBTYPE SLV8 IS STD_LOGIC_VECTOR(7 DOWNTO 0);
  SUBTYPE SLV10 IS STD_LOGIC_VECTOR(9 DOWNTO 0);
  SUBTYPE SLV26 IS STD_LOGIC_VECTOR(25 DOWNTO 0);
END n_bit_int;

LIBRARY work;
USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY cic3r32 IS     
  PORT (clk   : IN  STD_LOGIC; -- System clock
        reset : IN  STD_LOGIC; -- Asynchronous reset
        x_in  : IN  SLV8;      -- System input
        clk2  : OUT STD_LOGIC; -- Clock divider
        y_out : OUT SLV10);    -- System output
END cic3r32;
-- --------------------------------------------------------
ARCHITECTURE fpga OF cic3r32 IS

  SUBTYPE SLV26 IS STD_LOGIC_VECTOR(25 DOWNTO 0);

  TYPE    STATE_TYPE IS (hold, sample);
  SIGNAL  state    : STATE_TYPE ;
  SIGNAL  count    : U5;
  SIGNAL  x : SLV8;                  -- Registered input
  SIGNAL  sxtx : SLV26;              -- Sign extended input
  SIGNAL  i0, i1 , i2 : SLV26;    -- I section  0, 1, and 2
  SIGNAL  i2d1, i2d2, c1, c0 : SLV26;  
                                    -- I and COMB section 0
  SIGNAL  c1d1, c1d2, c2 : SLV26;-- COMB1
  SIGNAL  c2d1, c2d2, c3 : SLV26;-- COMB2
      
BEGIN

  FSM: PROCESS (reset, clk) 
  BEGIN
    IF reset = '1' THEN               -- Asynchronous reset
      state <= hold; 
      count <= 0;      
      clk2  <= '0';
    ELSIF rising_edge(clk) THEN  
      IF count = 31 THEN
        count <= 0;
        state <= sample;
        clk2  <= '1'; 
      ELSE
        count <= count + 1;
        state <= hold;
        clk2  <= '0';
      END IF;
    END IF;
  END PROCESS FSM;

  sxt: PROCESS (x)
  BEGIN
    sxtx(7 DOWNTO 0) <= x;
    FOR k IN 25 DOWNTO 8 LOOP
      sxtx(k) <= x(x'high);
    END LOOP;
  END PROCESS sxt;

  Int: PROCESS(clk, reset) 
  BEGIN
    IF reset = '1' THEN -- Asynchronous clear
      x <= (OTHERS => '0');  i0 <= (OTHERS => '0');
      i1 <= (OTHERS => '0');  i2 <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      x    <= x_in;
      i0   <= i0 + sxtx;        
      i1   <= i1 + i0 ;        
      i2   <= i2 + i1 ; 
    END IF;       
  END PROCESS Int;

  Comb: PROCESS(clk, reset, state)
  BEGIN
    IF reset = '1' THEN -- Asynchronous clear
      c0 <= (OTHERS => '0'); c1 <= (OTHERS => '0');
      c2 <= (OTHERS => '0'); c3 <= (OTHERS => '0');
      i2d1 <= (OTHERS => '0'); i2d2 <= (OTHERS => '0');
      c1d1 <= (OTHERS => '0'); c1d2 <= (OTHERS => '0');
      c2d1 <= (OTHERS => '0'); c2d2 <= (OTHERS => '0');      
    ELSIF rising_edge(clk) THEN
      IF state = sample THEN
        c0   <= i2;
        i2d1 <= c0;
        i2d2 <= i2d1;
        c1   <= c0 - i2d2;
        c1d1 <= c1;
        c1d2 <= c1d1;
        c2   <= c1  - c1d2;
        c2d1 <= c2;
        c2d2 <= c2d1;
        c3   <= c2  - c2d2;
      END IF;
    END IF;  
  END PROCESS Comb;

  y_out <= c3(25 DOWNTO 16);  -- i.e., c3 / 2**16

END fpga;
