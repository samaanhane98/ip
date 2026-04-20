LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE axi4s_bus_pkg IS
  TYPE t_axi4s_packet IS RECORD
    tvalid : STD_LOGIC;
    tlast : STD_LOGIC;
    tfirst : STD_LOGIC;
    tdata : STD_LOGIC_VECTOR;
    tuser : STD_LOGIC_VECTOR;
    tkeep : STD_LOGIC_VECTOR;
  END RECORD;

  SUBTYPE t_axi4s_packet_32 IS t_axi4s_packet(tdata(31 DOWNTO 0), tuser(31 DOWNTO 0), tkeep(7 DOWNTO 0));
END PACKAGE;