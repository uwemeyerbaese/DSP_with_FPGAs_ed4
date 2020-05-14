PACKAGE n_bits_int IS          -- User defined types
  SUBTYPE U2 IS INTEGER RANGE 0 TO 3;
  SUBTYPE U4 IS INTEGER RANGE 0 TO 15;
  SUBTYPE S8 IS INTEGER RANGE -128 TO 127;
  SUBTYPE S9 IS INTEGER RANGE -2**8 TO 2**8-1;
  SUBTYPE S17 IS INTEGER RANGE -2**16 TO 2**16-1;
  TYPE A0_3S8 IS ARRAY (0 TO 3) of S8;
  TYPE A0_2S9 IS ARRAY (0 TO 2) of S9;
  TYPE A0_4S17 IS ARRAY (0 TO 4) of S17;
END n_bits_int;

LIBRARY work;
USE work.n_bits_int.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_signed.ALL;
-- --------------------------------------------------------
ENTITY cmoms IS                          ------> Interface
  GENERIC (IL : INTEGER := 3);-- Input buffer length -1 
  PORT (clk        : IN  STD_LOGIC; -- System clock
        reset      : IN  STD_LOGIC; -- Asynchron reset
        count_o    : OUT U4;  -- Counter FSM
        ena_in_o   : OUT BOOLEAN; -- Sample input enable
        ena_out_o  : OUT BOOLEAN; -- Shift output enable 
        x_in       : IN  S8;  -- System input  
        xiir_o     : OUT S9; -- IIR filter output   
        c0_o, c1_o, c2_o, c3_o : OUT S9; -- C-MOMS matrix
        y_out      : OUT S9); -- System output
END cmoms;
-- --------------------------------------------------------
ARCHITECTURE fpga OF cmoms IS

  SIGNAL count  : U4; -- Cycle R_1*R_2
  SIGNAL t      : U2;
  SIGNAL ena_in, ena_out : BOOLEAN; -- FSM enables
  SIGNAL x, ibuf : A0_3S8;          -- TAP registers
  SIGNAL xiir : S9 := 0; -- iir filter output
  -- Precomputed value for d**k :
  CONSTANT d1 : A0_2S9 := (0,85,171);
  CONSTANT d2 : A0_2S9 := (0,28,114);
  CONSTANT d3 : A0_2S9 := (0,9,76);
  -- Spline matrix output: 
  SIGNAL c0, c1, c2, c3     : S9;

BEGIN

  FSM: PROCESS (reset, clk)    ------> Control the system 
  BEGIN                              -- sample at clk rate
    IF reset = '1' THEN              -- Asynchronous reset
      count <= 0;
      t <= 1;
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
        WHEN 3 | 7 | 11 =>   
          ena_out <= TRUE; 
         WHEN others => 
          ena_out <= FALSE;
      END CASE;
 -- Compute phase delay 
      IF ENA_OUT THEN 
        IF t >= 2 THEN
          t <= 0;
        ELSE
         t <= t + 1;
        END IF;
      END IF;
    END IF;
  END PROCESS FSM;

--  Coeffs: H(z)=1.5/(1+0.5z^-1)
  IIR: PROCESS(clk, reset)         ------> Behavioral Style
    VARIABLE x1 : S9;
  BEGIN   -- Compute iir coefficients first 
    IF reset = '1' THEN          -- Asynchronous clear
      xiir <= 0; x1 := 0;
    ELSIF rising_edge(clk) THEN  -- iir: 
      IF ENA_IN THEN
        xiir <= 3 * x1 / 2 - xiir / 2;
        x1 := x_in;
      END IF;
    END IF;
  END PROCESS;

  TAP: PROCESS(clk, reset, ENA_IN) 
  BEGIN                           --> One tapped delay line
    IF reset = '1' THEN -- Asynchronous clear
      FOR I IN 0 TO IL LOOP 
        ibuf(I) <= 0;      -- Clear one
      END LOOP; 
    ELSIF rising_edge(clk) THEN
      IF ENA_IN THEN
        FOR I IN 1 TO IL LOOP 
          ibuf(I-1) <= ibuf(I);      -- Shift one
        END LOOP;
        ibuf(IL) <= xiir;         -- Input in register IL
      END IF;
    END IF;
  END PROCESS;

  GET: PROCESS(clk, reset, ENA_OUT) 
  BEGIN                       --> Get 4 samples at one time
    IF reset = '1' THEN -- Asynchronous clear
      FOR I IN 0 TO IL LOOP 
        x(I) <= 0;      -- Clear one
      END LOOP; 
    ELSIF rising_edge(clk) THEN
      IF ENA_OUT THEN
        FOR I IN 0 TO IL LOOP -- take over input buffer
          x(I) <= ibuf(I);    
        END LOOP;
      END IF;
    END IF;
  END PROCESS;

  -- Compute sum-of-products:
  SOP: PROCESS (clk, reset, ENA_OUT) 
  VARIABLE y, y0, y1, y2, y3, h0, h1 : S17; 
  BEGIN                              -- pipeline registers
-- Matrix multiplier C-MOMS matrix: 
--    x(0)      x(1)      x(2)      x(3)
--    0.3333    0.6667    0          0
--   -0.8333    0.6667    0.1667     0
--    0.6667   -1.5       1.0       -0.1667
--   -0.1667    0.5      -0.5        0.1667
    IF reset = '1' THEN -- Asynchronous clear
      c0 <= 0;  c1 <= 0;  c2 <= 0;  c3 <= 0; 
      y0 := 0;  y1 := 0;  y2 := 0;  y3 := 0;
      y := 0; h0 := 0; h1 := 0; 
    ELSIF rising_edge(clk) THEN
      IF ENA_OUT THEN  
        c0 <= (85 * x(0) + 171 * x(1))/256;
        c1 <= (171 * x(1) - 213 * x(0) + 43 * x(2)) / 256;
        c2 <= (171 * x(0) - 43 * x(3))/256 - 3*x(1)/2+x(2);
        c3 <= 43 * (x(3) - x(0)) / 256 +  (x(1) - x(2))/2;
-- No Farrow structure, parallel LUT for delays
-- for u=0:3, y=y+f(u)*d^u; end;
        y :=  h0 + h1; -- Use pipelined adder tree
        h0 := y0 + y1;
        h1 := y2 + y3;
        y0 := c0 * 256;
        y1 := c1 * d1(t);
        y2 := c2 * d2(t);
        y3 := c3 * d3(t);
      END IF;
    END IF;
    y_out <= y/256; -- Connect to output
END PROCESS SOP;
  
  c0_o <= c0; -- Provide some test signal as outputs
  c1_o <= c1;
  c2_o <= c2;
  c3_o <= c3;
  count_o <= count;
  ena_in_o <= ena_in;
  ena_out_o <= ena_out;
  xiir_o <= xiir;

END fpga;
