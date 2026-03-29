LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axi4s_bus.ALL;
ENTITY axi4s_bus_converter_wrapper IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tlast : IN STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_tuser : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tlast : OUT STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_tuser : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE structure OF axi4s_bus_converter_wrapper IS
  SIGNAL stream_m2s : t_axi4s_m2s_32;
  SIGNAL stream_s2m : t_axi4s_s2m;
BEGIN

  stream_to_axi4s_bus_inst : ENTITY work.stream_to_axi4s_bus
    PORT MAP(
      clk => clk,
      reset => reset,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready,
      s_axis_tlast => s_axis_tlast,
      s_axis_tdata => s_axis_tdata,
      s_axis_tuser => s_axis_tuser,
      stream_out_m2s => stream_m2s,
      stream_out_s2m => stream_s2m
    );

  axi4s_bus_to_stream_inst : ENTITY work.axi4s_bus_to_stream
    PORT MAP(
      clk => clk,
      reset => reset,
      stream_in_m2s => stream_m2s,
      stream_in_s2m => stream_s2m,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,
      m_axis_tlast => m_axis_tlast,
      m_axis_tdata => m_axis_tdata,
      m_axis_tuser => m_axis_tuser
    );
END ARCHITECTURE;