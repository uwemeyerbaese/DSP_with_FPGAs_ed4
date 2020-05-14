PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE U4 IS INTEGER RANGE 0 TO 15;
  SUBTYPE S8 IS INTEGER RANGE -128 TO 127;
  SUBTYPE S9 IS INTEGER RANGE -2**8 TO 2**8-1;
  SUBTYPE S17 IS INTEGER RANGE -2**16 TO 2**16-1;
  TYPE A0_10S8 IS ARRAY (0 TO 10) of S8;
  TYPE A0_10S9 IS ARRAY (0 TO 10) of S9;
  TYPE A0_2S8 IS ARRAY (0 TO 2) of S8;
  TYPE A0_3S8 IS ARRAY (0 TO 3) of S8;
  TYPE A0_10S17 IS ARRAY (0 TO 10) of S17;
END n_bits_int;

LIBRARY work;
USE work.n_bits_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY rc_sinc IS                         ------> Interface
  GENERIC (OL : INTEGER := 2; -- Output buffer length -1
           IL : INTEGER := 3; -- Input buffer length -1 
           L  : INTEGER := 10 -- Filter length -1
           );
  PORT (clk        : IN  STD_LOGIC; -- System clock
        reset      : IN  STD_LOGIC; -- Asynchronous reset
        x_in       : IN  S8;  -- System input
        count_o    : OUT U4;  -- Counter FSM
        ena_in_o   : OUT BOOLEAN; -- Sample input enable
        ena_out_o  : OUT BOOLEAN; -- Shift output enable
        ena_io_o   : OUT BOOLEAN; -- Enable transfer2output
        f0_o       : OUT S9; -- First Sinc filter output
        f1_o       : OUT S9; -- Second Sinc filter output
        f2_o       : OUT S9; -- Third Sinc filter output        
        y_out      : OUT S9); -- System output
END rc_sinc;
-- --------------------------------------------------------
ARCHITECTURE fpga OF rc_sinc IS

  SIGNAL count  : U4; -- Cycle R_1*R_2
  SIGNAL ena_in, ena_out, ena_io : BOOLEAN; -- FSM enables
  -- Constant arrays for multiplier and taps:
  CONSTANT c0  : A0_10S9 
              := (-19,26,-42,106,212,-53,29,-21,16,-13,11); 
  CONSTANT c2  : A0_10S9 
              := (11,-13,16,-21,29,-53,212,106,-42,26,-19);
  SIGNAL x : A0_10S8; 
                             -- TAP registers for 3 filters
  SIGNAL ibuf : A0_3S8; -- TAP in registers
  SIGNAL obuf : A0_2S8; -- TAP out registers
  SIGNAL f0, f1, f2 : S9; -- Filter outputs

BEGIN

  FSM: PROCESS (reset, clk)     ------> Control the system 
  BEGIN                              -- sample at clk rate
    IF reset = '1' THEN              -- Asynchronous reset
      count <= 0;
    ELSIF rising_edge(clk) THEN  
      IF count = 11 THEN  
        count <= 0;
      ELSE
        count <= count + 1;
      END IF;
      CASE count IS
        WHEN 2 | 5 | 8 | 11 =>   
          ena_in <= TRUE; 
         WHEN others => 
          ena_in <= FALSE;
      END CASE;
      CASE count IS
        WHEN 4 | 8 =>   
          ena_out <= TRUE; 
         WHEN others => 
          ena_out <= FALSE;
      END CASE;
      IF COUNT = 0 THEN
        ena_io <= TRUE;
      ELSE
        ena_io <= FALSE;
      END IF;
    END IF;
  END PROCESS FSM;

  INPUTMUX: PROCESS(clk, reset) ----> One tapped delay line
  BEGIN
    IF reset = '1' THEN -- Asynchronous clear
      FOR I IN 0 TO IL LOOP 
        ibuf(I) <= 0;      -- Clear one
      END LOOP; 
    ELSIF rising_edge(clk) THEN
      IF ENA_IN THEN
        FOR I IN IL DOWNTO 1 LOOP 
          ibuf(I) <= ibuf(I-1);       -- shift one
        END LOOP;
        ibuf(0) <= x_in;             -- Input in register 0
      END IF;
    END IF;
  END PROCESS;

  OUPUTMUX: PROCESS(clk, reset) ----> One tapped delay line
  BEGIN
    IF reset = '1' THEN -- Asynchronous clear
      FOR I IN 0 TO OL LOOP 
        obuf(I) <= 0;      -- Clear one
      END LOOP; 
    ELSIF rising_edge(clk) THEN
      IF ENA_IO THEN  -- store 3 samples in output buffer
        obuf(0) <= f0 ;
        obuf(1) <= f1; 
        obuf(2) <= f2 ;
      ELSIF ENA_OUT THEN
        FOR I IN OL DOWNTO 1 LOOP 
          obuf(I) <= obuf(I-1);       -- shift one
        END LOOP;
      END IF;
    END IF;
  END PROCESS;

  TAP: PROCESS(clk, reset)    ------> One tapped delay line
  BEGIN                        -- get 4 samples at one time
    IF reset = '1' THEN -- Asynchronous clear
      FOR I IN 0 TO 10 LOOP 
        x(I) <= 0;      -- Clear register
      END LOOP; 
    ELSIF rising_edge(clk) THEN 
      IF ENA_IO THEN
        FOR I IN 0 TO 3 LOOP -- take over input buffer
          x(I) <= ibuf(I);    
        END LOOP;
        FOR I IN 4 TO 10 LOOP -- 0->4; 4->8 etc.
          x(I) <= x(I-4);       -- shift 4 taps
        END LOOP;
      END IF;
    END IF;
  END PROCESS;

  SOP0: PROCESS(clk, reset, x) --> Compute sum-of-products 
  VARIABLE sum : S17;                            -- for f0
  VARIABLE p : A0_10S17;
  BEGIN
    FOR I IN 0 TO L LOOP -- Infer L+1  multiplier
      p(I) := c0(I) * x(I);
    END LOOP;
    sum := p(0);
    FOR I IN 1 TO L  LOOP      -- Compute the direct
      sum := sum + p(I);         -- filter adds
    END LOOP;
    IF reset = '1' THEN -- Asynchronous clear
      f0 <= 0; 
    ELSIF rising_edge(clk) THEN
      f0 <= sum /256;
    END IF;
  END PROCESS SOP0;

  SOP1: PROCESS(clk, reset) --> Compute sum-of-products 
  BEGIN                                       -- for f1
    IF reset = '1' THEN -- Asynchronous clear
      f1 <= 0;
    ELSIF rising_edge(clk) THEN
      f1 <= x(5);  -- No scaling, i.e. unit inpulse
    END IF;
  END PROCESS SOP1;

  SOP2: PROCESS(clk, reset, x) --> Compute sum-of-products
  VARIABLE sum : S17;                            -- for f2
  VARIABLE p : A0_10S17;
  BEGIN
    FOR I IN 0 TO L LOOP -- Infer L+1  multiplier
      p(I) := c2(I) * x(I);
    END LOOP;
    sum := p(0);
    FOR I IN 1 TO L  LOOP      -- Compute the direct
      sum := sum + p(I);         -- filter adds
    END LOOP;
    IF reset = '1' THEN -- Asynchronous clear
      f2 <= 0; 
    ELSIF rising_edge(clk) THEN
      f2 <= sum /256;
    END IF;
  END PROCESS SOP2;
  
  f0_o <= f0;        -- Provide some test signal as outputs
  f1_o <= f1;
  f2_o <= f2;
  count_o <= count;
  ena_in_o <= ena_in;
  ena_out_o <= ena_out;
  ena_io_o <= ena_io;

  y_out <= obuf(OL); -- Connect to output

END fpga;
