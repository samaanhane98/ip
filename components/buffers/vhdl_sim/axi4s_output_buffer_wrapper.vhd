LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY axi4s_output_buffer_wrapper IS
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

ARCHITECTURE structure OF axi4s_output_buffer_wrapper IS
  SIGNAL tfirst : STD_LOGIC;
BEGIN
  axi4s_input_buffer_inst : ENTITY work.axi4s_output_buffer
    PORT MAP(
      clk => clk,
      reset => reset,
      packet_in.tvalid => s_axis_tvalid,
      packet_in.tlast => s_axis_tlast,
      packet_in.tfirst => '0',
      packet_in.tdata => s_axis_tdata,
      packet_in.tuser => s_axis_tuser,
      packet_in_ready => s_axis_tready,
      packet_out.tvalid => m_axis_tvalid,
      packet_out.tlast => m_axis_tlast,
      packet_out.tfirst => tfirst,
      packet_out.tdata => m_axis_tdata,
      packet_out.tuser => m_axis_tuser,
      packet_out_ready => m_axis_tready
    );
END ARCHITECTURE;