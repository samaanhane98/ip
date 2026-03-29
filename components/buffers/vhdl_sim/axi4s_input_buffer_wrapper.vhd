LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY axi4s_input_buffer_wrapper IS
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

ARCHITECTURE structure OF axi4s_input_buffer_wrapper IS
  SIGNAL tfirst : STD_LOGIC;
BEGIN
  axi4s_input_buffer_inst : ENTITY work.axi4s_input_buffer
    PORT MAP(
      clk => clk,
      reset => reset,
      stream_in_m2s.tvalid => s_axis_tvalid,
      stream_in_m2s.tlast => s_axis_tlast,
      stream_in_m2s.tfirst => '0',
      stream_in_m2s.tdata => s_axis_tdata,
      stream_in_m2s.tuser => s_axis_tuser,
      stream_in_s2m.tready => s_axis_tready,
      stream_out_m2s.tvalid => m_axis_tvalid,
      stream_out_m2s.tlast => m_axis_tlast,
      stream_out_m2s.tfirst => tfirst,
      stream_out_m2s.tdata => m_axis_tdata,
      stream_out_m2s.tuser => m_axis_tuser,
      stream_out_s2m.tready => m_axis_tready
    );
END ARCHITECTURE;