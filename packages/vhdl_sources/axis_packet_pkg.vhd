
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE axis_packet_pkg IS
  TYPE t_axis_packet IS RECORD
    valid : STD_LOGIC;
    last : STD_LOGIC;
    first : STD_LOGIC;
    data : STD_LOGIC_VECTOR;
    keep : STD_LOGIC_VECTOR;
    user : STD_LOGIC_VECTOR;
    meta_valid : STD_LOGIC;
  END RECORD;

  SUBTYPE t_axis_packet_32 IS t_axis_packet(data(31 DOWNTO 0), keep(3 DOWNTO 0), user(-1 DOWNTO 0));
  SUBTYPE t_axis_packet_64 IS t_axis_packet(data(63 DOWNTO 0), keep(7 DOWNTO 0), user(-1 DOWNTO 0));
END PACKAGE;

PACKAGE BODY axis_packet_pkg IS
END PACKAGE BODY axis_packet_pkg;