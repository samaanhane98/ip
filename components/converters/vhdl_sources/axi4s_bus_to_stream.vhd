LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axi4s_bus.ALL;
ENTITY axi4s_bus_to_stream IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    stream_in_m2s : IN t_axi4s_m2s_32;
    stream_in_s2m : OUT t_axi4s_s2m;

    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tlast : OUT STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_tuser : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE structure OF axi4s_bus_to_stream IS
BEGIN
  stream_in_s2m.tready <= m_axis_tready;
  m_axis_tvalid <= stream_in_m2s.tvalid;
  m_axis_tlast <= stream_in_m2s.tlast;
  m_axis_tdata <= stream_in_m2s.tdata;
  m_axis_tuser <= stream_in_m2s.tuser;

END ARCHITECTURE;