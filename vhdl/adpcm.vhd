-- This is a ADPCM demonstration for the IMA algorithm
PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE U3 IS INTEGER RANGE 0 TO 7;
  SUBTYPE U4 IS INTEGER RANGE 0 TO 15;
  SUBTYPE S5 IS INTEGER RANGE -16 TO 15;
  SUBTYPE S8 IS INTEGER RANGE -128 TO 127;
  SUBTYPE U15 IS INTEGER RANGE 0 TO 2**15-1;
  SUBTYPE S16 IS INTEGER RANGE -2**15 TO 2**15-1;
  SUBTYPE S17 IS INTEGER RANGE -2**16 TO 2**16-1;
  TYPE A0_7S5 IS ARRAY (0 TO 7) of S5;
  TYPE A0_88U15 IS ARRAY (0 TO 88) of U15;
END n_bits_int;

LIBRARY work; USE work.n_bits_int.ALL;

LIBRARY ieee; USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL; 
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY adpcm IS                      ------> Interface
      PORT ( clk    : IN  STD_LOGIC; -- System clock
             reset  : IN  STD_LOGIC;  -- Asynchronous reset
             x_in   : IN  S16; -- Input to encoder
             y_out  : OUT  U4; -- 4 bit ADPCM coding word
             p_out  : OUT S16; -- Predictor/decoder output
             p_underflow, p_overflow  : OUT STD_LOGIC; 
                                         -- Predictor flags
             i_out  : OUT S8;  -- Index to table                                         
             i_underflow, i_overflow  : OUT STD_LOGIC; 
                                             -- Index flags
             err    : OUT S16; -- Error of system
             sz_out : OUT U15; -- Step size
             s_out  : OUT STD_LOGIC); -- Sign bit
END adpcm;
-- --------------------------------------------------------
ARCHITECTURE fpga OF adpcm IS

  --  ADPCM step variation table 
  CONSTANT indexTable  : A0_7S5 :=(
    -1, -1, -1, -1, 2, 4, 6, 8);

  -- Quantization lookup table has 89 entries
  CONSTANT stepsizeTable :  A0_88U15 :=(
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 
    28, 31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 
    97, 107, 118, 130, 143, 157, 173, 190, 209, 230, 253,
    279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724,
    796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707,1878,
    2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 
    4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 
    11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385,
    24623, 27086, 29794, 32767);

  SIGNAL va, va_d : S16 := 0;-- Current signed adpcm input
  SIGNAL sign : STD_LOGIC;   -- Current adpcm sign bit  
  SIGNAL sdelta : U4;        -- Current signed adpcm output
  SIGNAL step : U15 := 7;    -- Stepsize 
  SIGNAL sstep : S16;        -- Stepsize including sign
  SIGNAL valpred : S16 := 0; -- Predicted output value 
  SIGNAL index : S8 := 0;    -- Current step change index        
                                               
BEGIN 

  Encode: PROCESS(clk, reset, x_in, va, sign, sdelta, step, 
                                            valpred, index)
  VARIABLE diff : S17;   -- Difference val - valprev
  VARIABLE p : S17 := 0; -- Next valpred
  VARIABLE i : S8;       -- Next index
  VARIABLE delta : U3;   -- Current absolute adpcm output
  VARIABLE tStep : U15;
  VARIABLE vpdiff : S16;       -- Current change to valpred
  BEGIN
    IF reset = '1' THEN -- Asynchronous clear
      va <= 0; va_d <= 0;
    ELSIF rising_edge(clk) THEN -- Store in register
      va <= x_in;
      va_d <= va;      -- Delay signal for error comparison
    END IF;
--------- State 1: Compute difference from predicted sample
    diff := va - valpred;
    sign <= '0';
    IF diff < 0 THEN
      sign <= '1';   --  Set sign bit if negative
      diff := -diff; -- Use absolute value for quantization
    END IF; 
-- State 2: Quantize by devision and 
-- State 3: compute inverse quantization
--  Compute:  delta=floor(diff(k)*4./step(k)); and
--  vpdiff(k)=floor((delta(k)+.5).*step(k)/4);
    delta := 0; tStep := step; vpdiff := tStep/8;
    IF diff >= tStep THEN
      delta := 4; diff := diff-tStep; 
      vpdiff := vpdiff + tStep;
    END IF;
    tStep := tStep/2;
    IF diff >= tStep THEN
      delta := delta + 2 ; diff := diff - tStep; 
      vpdiff := vpdiff + tStep;
    END IF;
    tStep := tStep/2;
    IF diff >= tStep THEN
      delta := delta + 1; diff := diff - tStep; 
      vpdiff := vpdiff + tStep;
    END IF;
  -- State 4: Adjust predicted sample based on inverse 
    IF sign = '1' THEN                       -- quantized
      p := valpred - vpdiff;
    ELSE               
      p := valpred + vpdiff;
    END IF;  
  --------- State 5: Threshold to maximum and minimum -----
    p_overflow <= '0'; p_underflow <= '0';
    IF p > 32767 THEN -- Check for 16 bit range
      p := 32767; -- 2^15-1 two's complement
      p_overflow <= '1';
    END IF;
    IF p < -32768 THEN
     p := -32768; -- -2^15
     p_underflow <= '1';
    END IF;
    IF reset = '1' THEN -- Asynchronous clear
      valpred <= 0;
    ELSIF rising_edge(clk) THEN 
      valpred <= p;          -- Store predicted in register
    END IF;
--- State 6: Update the stepsize and index for stepsize LUT
    i_underflow <= '0'; i_overflow <= '0';
    i := index + indexTable(delta);
    IF  i < 0 THEN -- Check index range [0...88]
      i := 0;
      i_underflow <= '1';
    END IF;
    IF i > 88 THEN
      i := 88;
      i_overflow <= '1';
    END IF;
    IF reset = '1' THEN -- Asynchronous clear
      step <= 0; index <= 0;
    ELSIF rising_edge(clk) THEN
      step <= stepsizeTable(i);
      index <= i;
    END IF;
    IF sign = '1' THEN
      sdelta <= delta + 8;
    ELSE
      sdelta <= delta;
    END IF; 
  END PROCESS;
   
    y_out  <= sdelta;    -- Monitor some test signals
    p_out  <= valpred;
    i_out  <= index;
    sz_out <= step;
    s_out  <= sign;
    err <= va_d-valpred;
    
END fpga;
