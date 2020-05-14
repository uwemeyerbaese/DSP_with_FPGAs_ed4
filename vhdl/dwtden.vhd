PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE U3 IS INTEGER RANGE 0 TO 7;
  SUBTYPE S16 IS INTEGER RANGE -2**15 TO 2**15-1;
  TYPE A0_11S16 IS ARRAY (0 TO 11) of S16;
  TYPE A0_29S16 IS ARRAY (0 TO 29) of S16;
END n_bits_int;

LIBRARY work;
USE work.n_bits_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY dwtden IS                          ------> Interface
  GENERIC (D1L : INTEGER := 28; -- D1 buffer length
           D2L : INTEGER := 10);-- D2 buffer length
  PORT (clk        : IN  STD_LOGIC; -- System clock
        reset      : IN  STD_LOGIC; -- Asynchron reset
        x_in       : IN  S16;  -- System input
        t4d1, t4d2, t4d3, t4a3 : IN S16;  -- Threshold
        d1_out     : OUT S16;  -- Level 1 detail
        a1_out     : OUT S16;  -- Level 1 approximation
        d2_out     : OUT S16;  -- Level 2 detail
        a2_out     : OUT S16;  -- Level 2 approximation
        d3_out     : OUT S16;  -- Level 3 detail
        a3_out     : OUT S16;  -- Level 3 approximation
        s3_out, a3up_out, d3up_out : OUT S16; -- L3 debug
        s2_out, s3up_out, d2up_out : OUT S16; -- L2 debug
        s1_out, s2up_out, d1up_out : OUT S16; -- L1 debug
        y_out      : OUT S16); -- System output
END dwtden;
-- --------------------------------------------------------
ARCHITECTURE fpga OF dwtden IS

  SIGNAL count  : U3; -- Cycle 2**max level
  SIGNAL x, xd  : S16; -- Input delays
  SIGNAL a1, d1, a2, d2, a3, d3 : S16; -- Analysis filter
  SIGNAL d1t, d2t, d3t, a3t : S16; -- Before thresholding
  SIGNAL a1up, a3up, d3up : S16;
  SIGNAL a1upd, s3upd, a3upd, d3upd : S16;
  SIGNAL a1d, a2d : S16; -- Delay filter output
  SIGNAL ena1, ena2, ena3 : BOOLEAN; -- Clock enables
  SIGNAL t1, t2, t3 : STD_LOGIC; -- Toggle flip-flops
  SIGNAL s2, s3up, s3, d2syn : S16;
  SIGNAL s1, s2up, s2upd : S16;
  -- Delay lines for d1 and d2 
  SIGNAL d2upd : A0_11S16;
  SIGNAL d1upd : A0_29S16;
BEGIN

  FSM: PROCESS (reset, clk)    ------> Control the system 
  BEGIN                              -- sample at clk rate
    IF reset = '1' THEN              -- Asynchronous reset
      count <= 0;
    ELSIF rising_edge(clk) THEN  
      IF count = 7 THEN  
        count <= 0;     
      ELSE
        count <= count + 1;
      END IF;
      CASE count IS    -- Level 1 enable
        WHEN 1 | 3 | 5 | 7 =>   
          ena1 <= TRUE; 
         WHEN others => 
          ena1 <= FALSE;
      END CASE;
      CASE count IS  -- Level 2 enable
        WHEN 1 | 5  =>   
          ena2 <= TRUE; 
         WHEN others => 
          ena2 <= FALSE;
      END CASE;
      CASE count IS   -- Level 3 enable
        WHEN 5  =>   
          ena3 <= TRUE; 
         WHEN others => 
          ena3 <= FALSE;
      END CASE;
    END IF;
  END PROCESS FSM;

--  Haar analysis filter bank 
  Analysis: PROCESS(clk, reset)    ------> Behavioral Style
  BEGIN   
    IF reset = '1' THEN          -- Asynchronous clear
      x <= 0; xd <= 0;
      d1t <= 0; a1 <= 0; a1d <= 0; 
      d2t <= 0; a2 <= 0; a2d <= 0;
      d3t <= 0; a3t <= 0;
    ELSIF rising_edge(clk) THEN
      x <= x_in;
      xd <= x;
      IF ena1 THEN -- Level 1 analysis
        d1t <= x - xd;
        a1  <= x + xd;
        a1d <= a1;              
      END IF;
      IF ena2 THEN -- Level 2 analysis
        d2t <= a1 - a1d;
        a2 <= a1 + a1d;  
        a2d <= a2; 
      END IF;
      IF ena3 THEN -- Level 3 analysis
        d3t <= a2 - a2d;
        a3t <= a2 + a2d;
      END IF;
    END IF;
  END PROCESS;

-- Thresholding of d1, d2, d3 and a3
    d1 <= d1t WHEN abs(d1t) > t4d1 ELSE 0;
    d2 <= d2t WHEN abs(d2t) > t4d2 ELSE 0;
    d3 <= d3t WHEN abs(d3t) > t4d3 ELSE 0;
    a3 <= a3t WHEN abs(a3t) > t4a3 ELSE 0;

-- Down followed by up sampling is implemented by setting 
-- every 2. value to zero
  Synthesis: PROCESS(clk, reset)   ------> Behavioral Style
  BEGIN    
    IF reset = '1' THEN          -- Asynchronous clear
      t1 <= '0'; t2 <= '0'; t3 <= '0';
      s3up <= 0;s3upd <= 0;
      d3up <= 0; a3up <= 0; a3upd<=0; d3upd <= 0;
      s3 <= 0; s2 <= 0;
      s1 <= 0; s2up <= 0; s2upd <= 0;
      FOR k IN 0 TO D2L+1 LOOP -- Clear array match s3up
          d2upd(k) <= 0;
      END LOOP;
      FOR k IN 0 TO D1L+1 LOOP -- Clear array match s2up
          d1upd(k) <= 0;
      END LOOP;
    ELSIF rising_edge(clk) THEN
        t1 <= NOT t1;  -- toggle FF level 1
        IF t1 = '1' THEN
          d1upd(0) <= d1;
          s2up <= s2;
        ELSE
          d1upd(0) <= 0;
          s2up <= 0;
        END IF; 
        s2upd <= s2up;
        FOR k IN 1 TO D1L+1 LOOP -- Delay to match s2up
          d1upd(k) <= d1upd(k-1);
        END LOOP;
        s1 <= (s2up + s2upd - d1upd(D1L) + d1upd(D1L+1))/2; 

      IF ena1 THEN
        t2 <= NOT t2; -- toggle FF level 2
        IF t2 = '1' THEN
          d2upd(0) <= d2;
          s3up <= s3;
        ELSE
          d2upd(0) <= 0;
          s3up <= 0;
        END IF; 
        s3upd <= s3up;
        FOR k IN 1 TO D2L+1 LOOP -- delay to match s3up
          d2upd(k) <= d2upd(k-1);
        END LOOP;
        s2 <= (s3up + s3upd - d2upd(D2L) + d2upd(D2L+1))/2;
      END IF;
      
      IF ena2 THEN -- Synthesis level 3
        t3 <= NOT t3; -- toggle FF
        IF t3='1' THEN
          d3up <= d3;
          a3up <= a3;
        ELSE
          d3up <= 0;
          a3up <= 0;
        END IF;  
        a3upd <= a3up;
        d3upd <= d3up;
        s3 <= (a3up + a3upd - d3up + d3upd)/2;       
      END IF;
    END IF;
  END PROCESS;
  
  a1_out <= a1; -- Provide some test signal as outputs
  d1_out <= d1;
  a2_out <= a2; 
  d2_out <= d2;
  a3_out <= a3; 
  d3_out <= d3;
  a3up_out <= a3up; 
  d3up_out <= d3up;
  s3_out <= s3;  
  s3up_out <= s3up; 
  d2up_out <= d2upd(D2L);
  s2_out <= s2;
  s1_out <= s1;
  s2up_out <= s2up;
  d1up_out <= d1upd(D1L);
  y_out <= s1;
  
END fpga;
