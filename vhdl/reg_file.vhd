-- Desciption: This is a W x L bit register file.
--             First register is set to zero.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_file IS
  GENERIC(W : INTEGER := 7; -- Bit width-1
          N : INTEGER := 15); -- Number of regs-1
  PORT(clk     : IN  STD_LOGIC;    -- System clock
       reset   : IN  STD_LOGIC;    -- Asynchronous reset 
       reg_ena : IN STD_LOGIC;     -- Write enable active 1
       data  : IN STD_LOGIC_VECTOR(W DOWNTO 0); -- Input
       rd : IN INTEGER RANGE 0 TO N;  -- Address for write
       rs : IN INTEGER RANGE 0 TO N;  -- 1. read address 
       rt : IN INTEGER RANGE 0 TO N;  -- 2. read address
       s : OUT STD_LOGIC_VECTOR(W DOWNTO 0);  -- 1. data
       t : OUT STD_LOGIC_VECTOR(W DOWNTO 0)); -- 2. data         
END;

ARCHITECTURE fpga OF reg_file IS

  SUBTYPE SLVW IS STD_LOGIC_VECTOR(W DOWNTO 0);
  TYPE SLV_NxW IS ARRAY (0 TO N) OF SLVW;
  SIGNAL r : SLV_NxW;

BEGIN

  MUX: PROCESS(clk, reset, data) -- Input mux inferring 
  BEGIN                                    -- registers
    IF reset = '1' THEN               -- Asynchronous clear
      FOR K IN 0 TO N LOOP
        r(k) <= (OTHERS => '0'); 
      END LOOP;
    ELSIF rising_edge(clk) THEN
      IF reg_ena = '1' AND rd > 0 THEN
        r(rd) <= data;
      END IF;
    END IF;  
  END PROCESS MUX;

  DEMUX: PROCESS (r, rs, rt) --  2 output demux 
  BEGIN                      --  without registers
    IF rs > 0 THEN -- First source
      s <= r(rs);
    ELSE
      s <= (OTHERS => '0');
    END IF;
    IF rt > 0 THEN -- Second source
      t <= r(rt);
    ELSE
      t <= (OTHERS => '0');
    END IF;
  END PROCESS DEMUX;
                 
END fpga;
