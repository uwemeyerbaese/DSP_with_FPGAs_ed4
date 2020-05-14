-- --------------------------------------------------------
ENTITY cmul7p8 IS                      ------> Interface
    PORT(x : IN  INTEGER RANGE -16 TO 15;  -- System input
       y0, y1, y2, y3 : OUT INTEGER RANGE -16 TO 15);
END;                        -- The 4 system outputs y=7*x/8
-- --------------------------------------------------------
ARCHITECTURE fpga OF cmul7p8 IS                 
BEGIN

  y0 <= 7 * x / 8;
  y1 <= x / 8 * 7;
  y2 <= x/2 + x/4 + x/8;
  y3 <= x - x/8;

END fpga;


