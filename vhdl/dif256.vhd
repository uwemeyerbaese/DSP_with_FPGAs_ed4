-- --------------------------------------------------------
-- Generic 256 point DIF FFT algorithm using a register 
-- array for data and coefficients
PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE U9 IS INTEGER RANGE 0 TO 2**9-1;
  SUBTYPE S16 IS INTEGER RANGE -2**15 TO 2**15-1;
  SUBTYPE S32 IS INTEGER RANGE -2147483647 TO 2147483647;
  TYPE ARRAY_L8S16 IS ARRAY (0 TO 7) of S16;
  TYPE ARRAY_L256S16 IS ARRAY (0 TO 255) of S16;
  TYPE ARRAY_L128S16 IS ARRAY (0 TO 127) of S16;
  TYPE STATE_TYPE IS 
                (start, load, calc, update, reverse, done);
END n_bits_int;

LIBRARY work; USE work.n_bits_int.ALL;

LIBRARY ieee; USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL; 
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY dif256 IS                          ------> Interface
  PORT (clk, reset : IN  STD_LOGIC; -- Clock and reset
        xr_in, xi_in   : IN  S16; -- Real and imag. input
        fft_valid : OUT STD_LOGIC; -- FFT output is valid
        fftr, ffti : OUT S16; -- Real and imag. output
        rcount_o : OUT U9; -- Bitreverese index counter 
    xr_out, xi_out : OUT ARRAY_L8S16; -- First 8 reg. files
        stage_o, gcount_o : OUT U9; --Stage and group count
        i1_o, i2_o : OUT U9; -- (Dual) data index 
        k1_o, k2_o : OUT U9; -- Index offset 
        w_o, dw_o  : OUT U9; -- Cos/Sin (increment) angle 
        wo : OUT U9);    -- Decision tree location loop FSM
END dif256;
-- --------------------------------------------------------
ARCHITECTURE fpga OF dif256 IS

  SIGNAL s    : STATE_TYPE; -- State machine variable
  CONSTANT N : U9 := 256; -- Number of points
  CONSTANT ldN : U9 := 8; -- Log_2 number of points
  -- Register array for 16 bit precision: 
  SIGNAL xr, xi : ARRAY_L256S16;
  SIGNAL w : U9 := 0;
  -- sine and cosine coefficient arrays
-- --------------------------------------------------------  
  CONSTANT cos_rom : ARRAY_L128S16 := (16384,16379,16364,16340
  ,16305,16261,16207,16143,16069,15986,15893,15791,15679,
  15557,15426,15286,15137,14978,14811,14635,14449,14256,
  14053,13842,13623,13395,13160,12916,12665,12406,12140,
  11866,11585,11297,11003,10702,10394,10080,9760,9434,9102,
  8765,8423,8076,7723,7366,7005,6639,6270,5897,5520,5139,
  4756,4370,3981,3590,3196,2801,2404,2006,1606,1205,804,402
  ,0,-402,-804,-1205,-1606,-2006,-2404,-2801,-3196,-3590,
  -3981,-4370,-4756,-5139,-5520,-5897,-6270,-6639,-7005,
  -7366,-7723,-8076,-8423,-8765,-9102,-9434,-9760,-10080,
  -10394,-10702,-11003,-11297,-11585,-11866,-12140,-12406,
  -12665,-12916,-13160,-13395,-13623,-13842,-14053,-14256,
  -14449,-14635,-14811,-14978,-15137,-15286,-15426,-15557,
  -15679,-15791,-15893,-15986,-16069,-16143,-16207,-16261,
  -16305,-16340,-16364,-16379);
-- --------------------------------------------------------   
  CONSTANT sin_rom : ARRAY_L128S16 := (0,402,804,1205,1606,
  2006,2404,2801,3196,3590,3981,4370,4756,5139,5520,5897,
  6270,6639,7005,7366,7723,8076,8423,8765,9102,9434,9760,
  10080,10394,10702,11003,11297,11585,11866,12140,12406,
  12665,12916,13160,13395,13623,13842,14053,14256,14449,
  14635,14811,14978,15137,15286,15426,15557,15679,15791,
  15893,15986,16069,16143,16207,16261,16305,16340,16364,
  16379,16384,16379,16364,16340,16305,16261,16207,16143,
  16069,15986,15893,15791,15679,15557,15426,15286,15137,
  14978,14811,14635,14449,14256,14053,13842,13623,13395,
  13160,12916,12665,12406,12140,11866,11585,11297,11003,
  10702,10394,10080,9760,9434,9102,8765,8423,8076,7723,
  7366,7005,6639,6270,5897,5520,5139,4756,4370,3981,3590,
  3196,2801,2404,2006,1606,1205,804,402);

  SIGNAL sin , cos : S16;
BEGIN

  sin_read: PROCESS (clk)
  BEGIN
    IF falling_edge(clk) THEN
      sin <= sin_rom(w); -- Read from ROM
    END IF;
  END PROCESS;
  
  cos_read: PROCESS (clk)
  BEGIN
    IF falling_edge(clk) THEN
      cos <= cos_rom(w); -- Read from ROM
    END IF;
  END PROCESS;
  
  States: PROCESS(clk, reset, w)-----> FFT in behavioral style
   VARIABLE i1, i2, gcount, k1, k2   : U9 := 0;
   VARIABLE stage, dw, count, rcount  : U9 := 0;
   VARIABLE tr, ti : S16 := 0;
   VARIABLE slv, rslv : STD_LOGIC_VECTOR(0 TO ldN-1);
  BEGIN
    IF reset = '1' THEN           -- Asynchronous reset
      s <= start;
    ELSIF rising_edge(clk) THEN 
      CASE s IS                 -- Next State assignments
      WHEN start =>
        s <= load; count := 0;
        gcount := 0; stage:= 1; i1:=0; i2 := N/2; k1:=N; 
        k2:=N/2; dw := 1; fft_valid <= '0';
      WHEN load =>       -- Read in all data from I/O ports
        xr(count) <= xr_in; xi(count) <= xi_in;
        count := count + 1;
        IF count = N THEN  s <= calc;
        ELSE               s <= load;
        END IF;
      WHEN calc =>          -- Do the butterfly computation
        tr := xr(i1) - xr(i2);
        xr(i1) <= xr(i1) + xr(i2);
        ti := xi(i1) - xi(i2);
        xi(i1) <= xi(i1) + xi(i2);
        xr(i2) <= (cos * tr + sin * ti)/2**14;
        xi(i2) <= (cos * ti - sin * tr)/2**14;
        s <= update;
      WHEN update =>           -- all counters and pointers
        s  <= calc; -- by default do next butterfly
        i1 := i1 + k1; -- next butterfly in group 
        i2 := i1 + k2; 
        wo <= 1;
        IF i1 >= N-1 THEN -- all butterfly done in group?
          gcount := gcount + 1;
          i1 := gcount;
          i2 := i1 + k2;
          wo <= 2;
          IF gcount >= k2 THEN-- all groups done in stages?
            gcount := 0; i1 := 0; i2 := k2;
            dw := dw * 2;
            stage  := stage + 1;
            wo <= 3;
            IF stage > ldn THEN -- all stages done
              s <= reverse;
              count := 0;
              wo <= 4;
            ELSE -- start new stage            
              k1 := k2; k2 := k2/2;
              i1 := 0; i2 := k2;
              w  <= 0;
              wo <= 5;
            END IF;
          ELSE -- start new group
            i1 := gcount;  i2 := i1 + k2;
            w <= w + dw;
            wo <= 6;
          END IF;
        END IF;
      WHEN reverse =>   -- Apply Bit Reverse
        fft_valid <= '1';
        slv := CONV_STD_LOGIC_VECTOR(count, ldn);
        FOR i IN 0 TO ldn-1 LOOP
          rslv(i) := slv(ldn-i-1);
        END LOOP;
        rcount := CONV_INTEGER('0' & rslv);
        fftr <= xr(rcount); ffti <= xi(rcount);
        count := count + 1;
        IF count >= N THEN  s <= done;
        ELSE                s <= reverse;
        END IF;
      WHEN done =>      -- Output of results
        s <= start;     -- start next cycle
      END CASE;
    END IF;
    i1_o<=i1;   -- Provide some test signals as outputs
    i2_o<=i2;   
    stage_o<=stage;
    gcount_o <= gcount;
    k1_o <= k1;
    k2_o<=k2;
    w_o<=w;
    dw_o<=dw;
    rcount_o <= rcount;
   END PROCESS States;  
   
   Rk: FOR k IN 0 TO 7 GENERATE -- Show first 8
     xr_out(k) <= xr(k);        -- register values
     xi_out(k) <= xi(k); 
   END GENERATE;

END fpga;
