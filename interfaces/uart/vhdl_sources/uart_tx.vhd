LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY uart_tx IS
  GENERIC (
    g_clock_frequency : INTEGER := 100000000;
    g_baud_rate : INTEGER := 115200;
    g_data_bits : INTEGER := 8;
    g_stop_bits : INTEGER := 1
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    tx : IN STD_LOGIC;

    m_axis_tdata : OUT STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);
    m_axis_tvalid : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE structure OF uart_tx IS
  CONSTANT c_bit_period : INTEGER := g_clock_frequency / g_baud_rate;
  CONSTANT c_bit_period2 : INTEGER := g_clock_frequency / (2 * g_baud_rate);

  TYPE t_uart_state IS (Idle, Start, Data, Stop);
  SIGNAL state : t_uart_state;

  SIGNAL data_i : STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);
  SIGNAL done_i : STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);

  SIGNAL tx_sync : STD_LOGIC;
BEGIN
  input_sync_inst : ENTITY work.input_sync
    GENERIC MAP(
      g_sync_stages => 2,
      g_reset_val => '1'
    )
    PORT MAP(
      input => tx,
      reset => reset,
      dest_clk => clk,
      output => tx_sync
    );

  p_state_machine : PROCESS (clk)
    VARIABLE v_count : INTEGER := 0;
  BEGIN
    IF rising_edge(clk) THEN
      m_axis_tvalid <= '0';

      CASE state IS
        WHEN Idle =>
          IF tx_sync = '0' THEN
            state <= Start;
          END IF;
          v_count := 0;
        WHEN Start =>
          IF v_count = c_bit_period2 THEN
            v_count := 0;
            state <= Data;
            done_i <= (0 => '1', OTHERS => '0');
          ELSE
            v_count := v_count + 1;
          END IF;
        WHEN Data =>
          IF v_count = c_bit_period THEN
            v_count := 0;
            data_i <= tx_sync & data_i(g_data_bits - 1 DOWNTO 1);
            done_i <= done_i(g_data_bits - 2 DOWNTO 0) & done_i(g_data_bits - 1);

            IF done_i(g_data_bits - 1) = '1' THEN
              state <= Stop;
            END IF;
          ELSE
            v_count := v_count + 1;
          END IF;

        WHEN Stop =>
          IF v_count = c_bit_period THEN
            v_count := 0;
            IF tx_sync = '1' THEN
              m_axis_tvalid <= '1';
              m_axis_tdata <= data_i;
            END IF;
            state <= Idle;
          ELSE
            v_count := v_count + 1;
          END IF;
        WHEN OTHERS =>
      END CASE;

      IF reset = '1' THEN
        state <= Idle;
        data_i <= (OTHERS => '0');
        done_i <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;