LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY uart_rx IS
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

    m_axis_tdata : OUT STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC;

    uart_error : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE structure OF uart_rx IS
  TYPE t_uart_state IS (Idle, Start, Data, Stop, Error);
  SIGNAL state : t_uart_state;

  SIGNAL timing_ena : STD_LOGIC;
  SIGNAL bit_period : STD_LOGIC;
  SIGNAL bit_period2 : STD_LOGIC;

  SIGNAL data_i : STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);
  SIGNAL done_i : STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);

  SIGNAL rx_sync : STD_LOGIC;
BEGIN
  input_sync_inst : ENTITY work.input_sync
    GENERIC MAP(
      g_sync_stages => 2,
      g_reset_val => '1'
    )
    PORT MAP(
      input => rx,
      reset => reset,
      dest_clk => clk,
      output => rx_sync
    );

  uart_timing_gen_inst : ENTITY work.uart_timing_gen
    GENERIC MAP(
      g_clock_frequency => g_clock_frequency,
      g_baud_rate => g_baud_rate
    )
    PORT MAP(
      clk => clk,
      ena => timing_ena,
      bit_period2 => bit_period2,
      bit_period => bit_period
    );

  p_state_machine : PROCESS (clk)
    VARIABLE v_count : INTEGER := 0;
  BEGIN
    IF rising_edge(clk) THEN
      uart_error <= '0';
      m_axis_tvalid <= '0';

      CASE state IS
        WHEN Idle =>
          IF rx_sync = '0' THEN
            timing_ena <= '1';
            state <= Start;
          END IF;
        WHEN Start =>
          IF bit_period2 = '1' THEN
            state <= Data;
            done_i <= (0 => '1', OTHERS => '0');
          END IF;
        WHEN Data =>
          IF bit_period = '1' THEN
            data_i <= rx_sync & data_i(g_data_bits - 1 DOWNTO 1);
            done_i <= done_i(g_data_bits - 2 DOWNTO 0) & done_i(g_data_bits - 1);

            IF done_i(g_data_bits - 1) = '1' THEN
              state <= Stop;
            END IF;
          END IF;

        WHEN Stop =>
          IF bit_period = '1' THEN
            timing_ena <= '0';
            IF rx_sync = '1' THEN
              m_axis_tvalid <= '1';
              m_axis_tdata <= data_i;
              timing_ena <= '0';
              state <= Idle;
            ELSE
              state <= Error;
            END IF;
          END IF;
        WHEN Error =>
          state <= Idle;
          uart_error <= '1';
      END CASE;

      IF reset = '1' THEN
        state <= Idle;
        data_i <= (OTHERS => '0');
        done_i <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;