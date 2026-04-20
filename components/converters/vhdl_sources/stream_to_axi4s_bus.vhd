LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axi4s_bus_pkg.ALL;
ENTITY stream_to_axi4s_bus_pkg IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tlast : IN STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_tuser : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    packet_out : OUT t_axi4s_packet_32;
    packet_out_ready : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE structure OF stream_to_axi4s_bus_pkg IS
  SIGNAL first : STD_LOGIC;
BEGIN

  s_axis_tready <= packet_out_ready;
  packet_out.tvalid <= s_axis_tvalid;
  packet_out.tlast <= s_axis_tlast;
  packet_out.tdata <= s_axis_tdata;
  packet_out.tuser <= s_axis_tuser;
  packet_out.tfirst <= first;

  p_delay_tlast : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF s_axis_tready = '1' AND s_axis_tvalid = '1' THEN
        first <= s_axis_tlast;
      END IF;

      IF reset = '1' THEN
        first <= '0';
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;