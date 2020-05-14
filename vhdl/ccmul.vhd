LIBRARY lpm; USE lpm.lpm_components.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; USE ieee.std_logic_arith.ALL;

ENTITY ccmul IS
  GENERIC (W2  : INTEGER := 17;    -- Multiplier bit width
           W1  : INTEGER := 9;     -- Bit width c+s sum
           W   : INTEGER := 8);    -- Input bit width 
  PORT (clk  : STD_LOGIC;  -- Clock for the output register
        reset : STD_LOGIC; -- Asynchronous reset
        x_in, y_in, c_in -- Inputs: real/x, imag./y and cos
                      : IN  STD_LOGIC_VECTOR(W-1 DOWNTO 0);
        cps_in, cms_in        -- Inputs cos +/- sin coeffs.
                     : IN  STD_LOGIC_VECTOR(W1-1 DOWNTO 0); 
        r_out, i_out     -- Results real/x and imag./y
                     : OUT STD_LOGIC_VECTOR(W-1 DOWNTO 0));
END ccmul;

ARCHITECTURE fpga OF ccmul IS

  SIGNAL x, y, c : STD_LOGIC_VECTOR(W-1 DOWNTO 0);       
                                      -- Inputs and outputs
  SIGNAL r, i, cmsy, cpsx, xmyc                 -- Products
                         : STD_LOGIC_VECTOR(W2-1 DOWNTO 0); 
  SIGNAL xmy, cps, cms, sxtx, sxty              -- x-y etc.
                         : STD_LOGIC_VECTOR(W1-1 DOWNTO 0); 

BEGIN
    x   <= x_in;   -- x 
    y   <= y_in;   -- j * y
    c   <= c_in;   -- cos
    cps <= cps_in; -- cos + sin
    cms <= cms_in; -- cos - sin

  PROCESS(clk, reset, r, i)
  BEGIN
    IF reset = '1' THEN -- Asynchronous clear
      r_out <= (OTHERS => '0'); i_out <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      r_out <= r(W2-3 DOWNTO W-1);    -- Scaling and FF 
      i_out <= i(W2-3 DOWNTO W-1);    -- for output
    END IF;
  END PROCESS;
---------- ccmul with 3 mul. and 3 add/sub  ---------------
  sxtx  <= x(x'high) & x;        -- Possible growth for 
  sxty  <= y(y'high) & y;        -- sub_1 -> sign extension

  sub_1: lpm_add_sub                        -- Sub:  x - y;
    GENERIC MAP (  LPM_WIDTH => W1, LPM_DIRECTION => "SUB", 
                   LPM_REPRESENTATION => "SIGNED")
    PORT MAP (dataa => sxtx, datab => sxty, result => xmy);

  mul_1: lpm_mult               -- Multiply  (x-y)*c = xmyc
    GENERIC MAP ( LPM_WIDTHA => W1, LPM_WIDTHB => W,
                  LPM_WIDTHP => W2, LPM_WIDTHS => W2, 
                  LPM_REPRESENTATION => "SIGNED")
    PORT MAP ( dataa => xmy, datab => c, result => xmyc);

  mul_2: lpm_mult                -- Multiply (c-s)*y = cmsy
    GENERIC MAP ( LPM_WIDTHA => W1, LPM_WIDTHB => W,
                  LPM_WIDTHP => W2, LPM_WIDTHS => W2, 
                  LPM_REPRESENTATION => "SIGNED")  
    PORT MAP ( dataa => cms, datab => y, result => cmsy);

  mul_3: lpm_mult                -- Multiply (c+s)*x = cpsx
    GENERIC MAP ( LPM_WIDTHA => W1, LPM_WIDTHB => W,
                  LPM_WIDTHP => W2, LPM_WIDTHS => W2, 
                  LPM_REPRESENTATION => "SIGNED")  
    PORT MAP ( dataa => cps, datab => x, result => cpsx);

  sub_2: lpm_add_sub        -- Sub: i <= (c+s)*x - (x-y)*c;
    GENERIC MAP ( LPM_WIDTH => W2, LPM_DIRECTION => "SUB",
                  LPM_REPRESENTATION => "SIGNED")  
    PORT MAP ( dataa => cpsx, datab => xmyc, result => i);

  add_1: lpm_add_sub        -- Add: r <= (x-y)*c + (c-s)*y;
    GENERIC MAP ( LPM_WIDTH => W2, LPM_DIRECTION => "ADD", 
                  LPM_REPRESENTATION => "SIGNED")  
    PORT MAP ( dataa => cmsy, datab => xmyc, result => r);
    
END fpga;
