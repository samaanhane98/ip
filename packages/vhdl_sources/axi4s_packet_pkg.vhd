
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE axi4s_packet_pkg IS
  TYPE t_axi4s_packet IS RECORD
    valid : STD_LOGIC;
    last : STD_LOGIC;
    first : STD_LOGIC;
    data : STD_LOGIC_VECTOR;
    keep : STD_LOGIC_VECTOR;
    user : STD_LOGIC_VECTOR;
    meta_valid : STD_LOGIC;
  END RECORD;

  SUBTYPE t_axi4s_packet_32 IS t_axi4s_packet(data(31 DOWNTO 0), keep(7 DOWNTO 0));
END PACKAGE;