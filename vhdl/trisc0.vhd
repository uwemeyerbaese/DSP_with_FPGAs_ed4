-- Title: T-RISC stack machine 4/e
-- Description: This is the top control path/FSM of the 
-- T-RISC, with a single 3 phase clock cycle design
-- It has a stack machine/0-address type instruction word
-- The stack has only 4 words.
LIBRARY ieee; USE ieee.std_logic_1164.ALL;

PACKAGE n_bit_int IS               -- User defined types
  SUBTYPE SLVA IS STD_LOGIC_VECTOR(7 DOWNTO 0);
  SUBTYPE SLVD IS STD_LOGIC_VECTOR(7 DOWNTO 0);
  SUBTYPE SLVP IS STD_LOGIC_VECTOR(11 DOWNTO 0);
END n_bit_int;

LIBRARY work;
USE work.n_bit_int.ALL;

LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_arith.ALL;
USE ieee.STD_LOGIC_signed.ALL;

ENTITY trisc0 IS 
 GENERIC (WA : INTEGER := 7;   -- Address bit width -1
          WD : INTEGER := 7);  -- Data bit width -1
 PORT(clk     : IN  STD_LOGIC; -- System clock
      reset   : IN  STD_LOGIC; -- Asynchronous reset
      jc_OUT  : OUT BOOLEAN;   -- Jump condition flag
      me_ena  : OUT STD_LOGIC; -- Memory enable
      iport   : IN  SLVD;      -- Input port
      oport   : OUT SLVD;      -- Output port
      s0_OUT  : OUT SLVD;      -- Stack register 0
      s1_OUT  : OUT SLVD;      -- Stack register 1
      dmd_IN  : OUT SLVD;      -- Data memory data read
      dmd_OUT : OUT SLVD;      -- Data memory data write
      pc_OUT  : OUT SLVA;      -- Progamm counter   
      dma_OUT : OUT SLVA;      -- Data memory address write
      dma_IN  : OUT SLVA;      -- Data memory address read                          
      ir_imm  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
                               -- Immidiate value 
      op_code : OUT STD_LOGIC_VECTOR(3 DOWNTO 0));
END;                           -- Operation code

ARCHITECTURE fpga OF trisc0 IS

  SIGNAL op   : STD_LOGIC_VECTOR(3 DOWNTO 0);   
  SIGNAL imm, s0, s1, s2, s3, dmd : SLVD;
  SIGNAL pc, dma : SLVA;
  SIGNAL pmd, ir   : SLVP;
  SIGNAL eq, ne, mem_ena, not_clk : STD_LOGIC;
  SIGNAL jc       :  boolean;

-- OP Code of instructions:
  CONSTANT add   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"0";
  CONSTANT neg   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"1";
  CONSTANT sub   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"2";
  CONSTANT opand : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"3";
  CONSTANT opor  : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"4";
  CONSTANT inv   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"5";
  CONSTANT mul   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"6";
  CONSTANT pop   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"7";
  CONSTANT pushi : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"8";
  CONSTANT push  : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"9";
  CONSTANT scan  : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"A";
  CONSTANT print : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"B";
  CONSTANT cne   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"C";
  CONSTANT ceq   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"D";
  CONSTANT cjp   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"E";
  CONSTANT jmp   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"F";
  
-- Programm ROM definition and value
  TYPE MEMP IS ARRAY (0 TO 19) OF SLVP;
  CONSTANT prom : MEMP :=
  (X"801", X"700", X"a00", X"701", X"901", X"801", X"c00",
   X"e11", X"900", X"901", X"600", X"700", X"901", X"801",
   X"200", X"701", X"f04", X"900", X"b00", X"F00");
  
-- Data memory definition
  TYPE MEMD IS ARRAY(0 TO 2**(WA+1)-1) OF SLVD;
  SIGNAL dram : MEMD;

BEGIN

  P1: PROCESS (clk, reset, op) -- FSM of processor
  BEGIN -- store in register ? 
      CASE op IS -- always store except Branch
        WHEN pop    => mem_ena <= '1';
        WHEN OTHERS => mem_ena <= '0';
      END CASE;
      IF reset = '1' THEN
        pc <= (OTHERS => '0');
      ELSIF falling_edge(clk) THEN
        IF ((op=cjp) AND NOT jc ) OR  (op=jmp) THEN
          pc <= imm;
        ELSE 
          pc <= pc + "00000001"; 
        END IF;
      END IF;
      IF reset = '1' THEN
        jc <= false;
      ELSIF rising_edge(clk) THEN
        jc <= (op=ceq AND s0=s1) OR (op=cne AND s0/=s1);
      END IF;
  END PROCESS p1;

  -- Mapping of the instruction, i.e., decode instruction
  op   <= ir(11 DOWNTO 8);   -- Operation code
  dma  <= ir(7 DOWNTO 0);    -- Data memory address
  imm  <= ir(7 DOWNTO 0);    -- Immidiate operand

  prog_rom: PROCESS (clk, reset)
  BEGIN
    IF reset = '1' THEN               -- Asynchronous clear
      pmd <= (OTHERS => '0');     
    ELSIF rising_edge(clk) THEN
        pmd <= prom(CONV_INTEGER(pc)); -- Read from ROM
    END IF;
  END PROCESS;
  ir <= pmd;

  data_ram: PROCESS (clk, reset, dram, dma)
  VARIABLE idma : INTEGER RANGE 0 TO 255;
  BEGIN
    idma := CONV_INTEGER('0' & dma); -- force unsigned
    IF reset = '1' THEN               -- Asynchronous clear
      dmd <= (OTHERS => '0');          
    ELSIF falling_edge(clk) THEN
      IF mem_ena = '1' THEN
        dram(idma) <= s0;  -- Write to RAM
      END IF;
      dmd <= dram(idma);  -- Read from RAM    
    END IF;
  END PROCESS;
  
  P3: PROCESS (clk, reset, op)
  VARIABLE temp: STD_LOGIC_VECTOR(2*WD+1 DOWNTO 0);
  BEGIN
    IF reset = '1' THEN               -- Asynchronous clear
      s0 <= (OTHERS => '0'); s1 <= (OTHERS => '0');
      s2 <= (OTHERS => '0'); s3 <= (OTHERS => '0'); 
      oport <= (OTHERS => '0');     
    ELSIF rising_edge(clk) THEN
      CASE op IS            -- Specify the stack operations
        WHEN pushi | push | scan => s3<=s2; s2<=s1; s1<=s0;
                                               -- Push type
        WHEN cjp | jmp | inv | neg => NULL;   
                                   -- Do nothing for branch
        WHEN OTHERS =>   s1<=s2; s2<=s3; s3<=(OTHERS=>'0');
                                          -- Pop all others
      END CASE;    
      CASE op IS
        WHEN add    =>   s0  <= s0 + s1;
        WHEN neg    =>   s0  <= -s0;
        WHEN sub    =>   s0  <= s1 - s0;
        WHEN opand  =>   s0  <= s0 AND s1;
        WHEN opor   =>   s0  <= s0 OR s1;
        WHEN inv    =>   s0  <= NOT s0; 
        WHEN mul    =>   temp  := s0 * s1;
                         s0  <= temp(WD DOWNTO 0);
        WHEN pop    =>   s0  <= s1;
        WHEN push   =>   s0  <= dmd;
        WHEN pushi  =>   s0  <= imm;
        WHEN scan   =>   s0 <= iport;
        WHEN print  =>   oport <= s0; s0<=s1;
        WHEN OTHERS =>   s0 <= (OTHERS => '0');
      END CASE;
    END IF;
  END PROCESS P3;

  -- Extra test pins:
  dmd_OUT <= dmd; dma_OUT <= dma; -- Data memory I/O
  dma_IN <= dma; dmd_IN  <= s0;
  pc_OUT <= pc; ir_imm <= imm; op_code <= op;  
                                                 -- Program
  jc_OUT <= jc; me_ena <= mem_ena; -- Control signals
  s0_OUT <= s0; s1_OUT <= s1;     -- Two top stack elements

END fpga;
