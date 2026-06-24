LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axis_pkg.ALL;
ENTITY axis_pkg_to_stream IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    stream_in : IN t_axis_32;
    stream_in_ready : OUT STD_LOGIC;

    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tlast : OUT STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_tuser : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE structure OF axis_pkg_to_stream IS
BEGIN
  stream_in_ready <= m_axis_tready;
  m_axis_tvalid <= stream_in.tvalid;
  m_axis_tlast <= stream_in.tlast;
  m_axis_tdata <= stream_in.tdata;
  m_axis_tuser <= stream_in.tuser;

END ARCHITECTURE;