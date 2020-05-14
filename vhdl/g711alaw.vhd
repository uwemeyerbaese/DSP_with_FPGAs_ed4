--  G711 includes A and mu-law coding for speech signals:
--  A ~= 87.56; |x|<= 4095, i.e., 12 bit plus sign
--  mu~=255; |x|<=8160, i.e., 14 bit
LIBRARY ieee; USE ieee.std_logic_1164.ALL;
PACKAGE n_bit_int IS               -- User defined types 
  SUBTYPE SLV8 IS STD_LOGIC_VECTOR(7 DOWNTO 0);
  SUBTYPE SLV12 IS STD_LOGIC_VECTOR(11 DOWNTO 0);  
  SUBTYPE SLV13 IS STD_LOGIC_VECTOR(12 DOWNTO 0);
  SUBTYPE S13 IS INTEGER RANGE  -2**12 TO 2**12-1;  
END n_bit_int;
LIBRARY work; USE work.n_bit_int.ALL;

LIBRARY ieee; USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL; 
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY g711alaw IS
  GENERIC ( WIDTH     : INTEGER := 13);    -- Bit width
  PORT (clk   : IN  STD_LOGIC;  -- System clock
        reset : IN  STD_LOGIC;  -- Asynchronous reset
        x_in  : IN  SLV13;      -- System input
        enc   : BUFFER SLV8;    -- Encoder output
        dec   : BUFFER SLV13;   -- Decoder output
        err   : OUT S13 := 0);  -- Error of results
END g711alaw;                           
-- --------------------------------------------------------
ARCHITECTURE fpga OF g711alaw IS

  SIGNAL s, s_d   : STD_LOGIC;
  SIGNAL abs_x, x, x_d, x_dd : SLV13; -- Auxiliary vectors
  SIGNAL temp : SLV12;
                                       
BEGIN
  
  s <= x_in(WIDTH-1); -- sign magnitude not 2C!
  abs_x <= '0' & x_in(WIDTH-2 DOWNTO 0);                  
  err <= abs(conv_integer('0'&dec)-conv_integer('0'&x_in));

  Encode: PROCESS(abs_x, s) 
  BEGIN               -- Mini floating-point format encoder
    CASE conv_integer('0' & abs_x) IS
      WHEN 0    TO 63   => 
         enc <= s & "00"  & abs_x(5 DOWNTO 1); -- segment 1
      WHEN 64   TO 127  => 
         enc <= s & "010" & abs_x(5 DOWNTO 2); -- segment 2
      WHEN 128  TO 255  => 
         enc <= s & "011" & abs_x(6 DOWNTO 3); -- segment 3
      WHEN 256  TO 511  => 
         enc <= s & "100" & abs_x(7 DOWNTO 4); -- segment 4
      WHEN 512  TO 1023 => 
         enc <= s & "101" & abs_x(8 DOWNTO 5); -- segment 5
      WHEN 1024 TO 2047 => 
         enc <= s & "110" & abs_x(9 DOWNTO 6); -- segment 6
      WHEN 2048 TO 4095 => 
         enc <= s & "111" & abs_x(10 DOWNTO 7);-- segment 7
      WHEN OTHERS      => enc <= s & "0000000"; -- + or - 0
    END CASE;
  END PROCESS;
  
  Decode: PROCESS(enc, s) 
  BEGIN               -- Mini floating point format decoder
    CASE conv_integer('0' & enc(6 DOWNTO 4)) IS
      WHEN  0 | 1 => 
              dec <= s & "000000" & enc(4 DOWNTO 0)  & "1";
      WHEN  2     => 
              dec <= s & "000001" & enc(3 DOWNTO 0) & "10";
      WHEN  3     => 
              dec <= s & "00001" & enc(3 DOWNTO 0) & "100";
      WHEN  4     => 
              dec <= s & "0001" & enc(3 DOWNTO 0) & "1000";
      WHEN  5     => 
              dec <= s & "001" & enc(3 DOWNTO 0) & "10000";
      WHEN  6     => 
              dec <= s & "01" & enc(3 DOWNTO 0) & "100000";
      WHEN OTHERS => 
              dec <= s & "1" & enc(3 DOWNTO 0) & "1000000";
    END CASE;
  END PROCESS;
             
END fpga;
