-- ROMs Using Block RAM Resources
-- see ISE help "Inferring BlockRAM in VHDL"
-- or the ISE VHDL language templates
-- Copyright (c) Uwe Meyer-Baese

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

ENTITY sine256x8 IS
  PORT (clk : IN STD_LOGIC;
       addr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
       data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END;

ARCHITECTURE fpga OF sine256x8 IS

  TYPE rom_type IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
  CONSTANT rom : rom_type := (
  X"80",X"83",X"86",X"89",X"8c",X"90",X"93",X"96",X"99",X"9c",X"9f",
  X"a2",X"a5",X"a8",X"ab",X"ae",X"b1",X"b4",X"b6",X"b9",X"bc",X"bf",
  X"c2",X"c4",X"c7",X"c9",X"cc",X"ce",X"d1",X"d3",X"d6",X"d8",X"da",
  X"dc",X"de",X"e0",X"e2",X"e4",X"e6",X"e8",X"ea",X"ec",X"ed",X"ef",
  X"f0",X"f2",X"f3",X"f4",X"f6",X"f7",X"f8",X"f9",X"fa",X"fb",X"fb",
  X"fc",X"fd",X"fd",X"fe",X"fe",X"fe",X"ff",X"ff",X"ff",X"ff",X"ff",
  X"ff",X"ff",X"fe",X"fe",X"fd",X"fd",X"fc",X"fc",X"fb",X"fa",X"f9",
  X"f8",X"f7",X"f6",X"f5",X"f4",X"f2",X"f1",X"f0",X"ee",X"ec",X"eb",
  X"e9",X"e7",X"e5",X"e3",X"e1",X"df",X"dd",X"db",X"d9",X"d7",X"d4",
  X"d2",X"d0",X"cd",X"cb",X"c8",X"c5",X"c3",X"c0",X"bd",X"bb",X"b8",
  X"b5",X"b2",X"af",X"ac",X"a9",X"a7",X"a4",X"a0",X"9d",X"9a",X"97",
  X"94",X"91",X"8e",X"8b",X"88",X"85",X"82",X"7e",X"7b",X"78",X"75",
  X"72",X"6f",X"6c",X"69",X"66",X"63",X"60",X"5c",X"59",X"57",X"54",
  X"51",X"4e",X"4b",X"48",X"45",X"43",X"40",X"3d",X"3b",X"38",X"35",
  X"33",X"30",X"2e",X"2c",X"29",X"27",X"25",X"23",X"21",X"1f",X"1d",
  X"1b",X"19",X"17",X"15",X"14",X"12",X"10",X"0f",X"0e",X"0c",X"0b",
  X"0a",X"09",X"08",X"07",X"06",X"05",X"04",X"04",X"03",X"03",X"02",
  X"02",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"02",X"02",X"02",
  X"03",X"03",X"04",X"05",X"05",X"06",X"07",X"08",X"09",X"0a",X"0c",
  X"0d",X"0e",X"10",X"11",X"13",X"14",X"16",X"18",X"1a",X"1c",X"1e",
  X"20",X"22",X"24",X"26",X"28",X"2a",X"2d",X"2f",X"32",X"34",X"37",
  X"39",X"3c",X"3e",X"41",X"44",X"47",X"4a",X"4c",X"4f",X"52",X"55",
  X"58",X"5b",X"5e",X"61",X"64",X"67",X"6a",X"6d",X"70",X"74",X"77",
  X"7a",X"7d",X"80");

BEGIN
  -- The following process will be mapped to a BlockRAM for Virtex/Spartan
  -- devices (if addr > 3 bit!) and to Distributed RAM in all other cases

  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      data <= rom(conv_integer(addr));
    END IF;
  END PROCESS;

END fpga;
