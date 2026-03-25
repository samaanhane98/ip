LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY uart IS
  GENERIC (
    g_clock_frequency : INTEGER := 100000000;
    g_baud_rate : INTEGER := 115200;
    g_data_bits : INTEGER := 8;
    g_stop_bits : INTEGER := 1
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    rx : IN STD_LOGIC;
    tx : OUT STD_LOGIC;

    m_axis_tdata : OUT STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC;

    s_axis_tdata : IN STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;

    uart_error : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE structure OF uart IS
  SIGNAL s_tdata : STD_LOGIC_VECTOR(s_axis_tdata'RANGE);
  SIGNAL s_tvalid : STD_LOGIC;
  SIGNAL s_tready : STD_LOGIC;
BEGIN
  uart_rx_inst : ENTITY work.uart_rx
    GENERIC MAP(
      g_clock_frequency => g_clock_frequency,
      g_baud_rate => g_baud_rate,
      g_data_bits => g_data_bits,
      g_stop_bits => g_stop_bits
    )
    PORT MAP(
      clk => clk,
      reset => reset,
      rx => rx,
      m_axis_tdata => m_axis_tdata,
      m_axis_tvalid => m_axis_tvalid,
      uart_error => uart_error
    );

  axis_fifo_inst : ENTITY work.axis_fifo
    GENERIC MAP(
      g_word_depth => 16,
      g_tdata_width => 8,
      g_tuser_width => 0
    )
    PORT MAP(
      clk => clk,
      reset => reset,
      s_axis_tvalid => s_axis_tvalid,
      s_axis_tready => s_axis_tready,
      s_axis_tlast => '0',
      s_axis_tdata => s_axis_tdata,
      s_axis_tuser => "0",
      m_axis_tvalid => s_tvalid,
      m_axis_tready => s_tready,
      m_axis_tlast => OPEN,
      m_axis_tdata => s_tdata,
      m_axis_tuser => OPEN
    );

  uart_tx_inst : ENTITY work.uart_tx
    GENERIC MAP(
      g_clock_frequency => g_clock_frequency,
      g_baud_rate => g_baud_rate,
      g_data_bits => g_data_bits,
      g_stop_bits => g_stop_bits
    )
    PORT MAP(
      clk => clk,
      reset => reset,
      tx => tx,
      s_axis_tdata => s_tdata,
      s_axis_tvalid => s_tvalid,
      s_axis_tready => s_tready
    );
END ARCHITECTURE;