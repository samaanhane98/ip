LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
PACKAGE axis_pkg IS
  TYPE t_axis IS RECORD
    tvalid : STD_LOGIC;
    tlast : STD_LOGIC;
    tdata : STD_LOGIC_VECTOR;
    tuser : STD_LOGIC_VECTOR;
    tkeep : STD_LOGIC_VECTOR;
    tmeta : STD_LOGIC_VECTOR;
  END RECORD;

  SUBTYPE t_axis_32 IS t_axis(
  tdata(31 DOWNTO 0),
  tkeep(3 DOWNTO 0),
  tuser(-1 DOWNTO 0),
  tmeta(1 DOWNTO 0)
  );

  SUBTYPE t_axis_64 IS t_axis(
  tdata(63 DOWNTO 0),
  tkeep(7 DOWNTO 0),
  tuser(-1 DOWNTO 0),
  tmeta(1 DOWNTO 0)
  );
END PACKAGE;

PACKAGE BODY axis_pkg IS
END PACKAGE BODY axis_pkg;