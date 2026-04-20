LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axi4s_bus_pkg.ALL;
ENTITY axi4s_bus_pkg_to_stream IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    packet_in : IN t_axi4s_packet_32;
    packet_in_ready : OUT STD_LOGIC;

    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tlast : OUT STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_tuser : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE structure OF axi4s_bus_pkg_to_stream IS
BEGIN
  packet_in_ready <= m_axis_tready;
  m_axis_tvalid <= packet_in.tvalid;
  m_axis_tlast <= packet_in.tlast;
  m_axis_tdata <= packet_in.tdata;
  m_axis_tuser <= packet_in.tuser;

END ARCHITECTURE;