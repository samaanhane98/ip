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
  CONSTANT c_bit_period : INTEGER := g_clock_frequency / g_baud_rate;
  CONSTANT c_baud_tick_period : INTEGER := c_bit_period / 16;

  SIGNAL sample_ena : STD_LOGIC;
  SIGNAL baud_tick : STD_LOGIC;
  SIGNAL sample : STD_LOGIC;

  TYPE t_uart_state IS (Idle, Start, Data, Stop, Error);
  SIGNAL state : t_uart_state;

  SIGNAL rx_ft : STD_LOGIC;

  SIGNAL data_i : STD_LOGIC_VECTOR(m_axis_tdata'RANGE);
  SIGNAL bit_index : STD_LOGIC_VECTOR(m_axis_tdata'RANGE);
BEGIN

  uart_sample_gen_inst : ENTITY work.uart_sample_gen
    GENERIC MAP(
      g_clock_frequency => g_clock_frequency,
      g_baud_rate => g_baud_rate,
      g_data_bits => g_data_bits,
      g_stop_bits => g_stop_bits,
      g_include_first_bit => true
    )
    PORT MAP(
      clk => clk,
      reset => reset,
      ena => sample_ena,
      baud_tick => baud_tick,
      sample => sample
    );

  async_filter_inst : ENTITY work.async_filter
    PORT MAP(
      clk => clk,
      reset => reset,
      sample_clk => baud_tick,
      data_async => rx,
      data_ft => rx_ft
    );
  sample_ena <= '0' WHEN state = Idle ELSE
    '1';

  p_state_machine : PROCESS (clk)
    VARIABLE v_count : INTEGER := 0;
  BEGIN
    IF rising_edge(clk) THEN
      uart_error <= '0';
      m_axis_tvalid <= '0';

      CASE state IS
        WHEN Idle =>
          bit_index <= (OTHERS => '0');
          data_i <= (OTHERS => '0');
          IF rx_ft = '0' THEN
            state <= Start;
          END IF;
        WHEN Start =>
          IF sample = '1' THEN
            IF rx_ft = '0' THEN
              bit_index(bit_index'left) <= '1';
              state <= Data;
            ELSE
              state <= Idle;
            END IF;
          END IF;
        WHEN Data =>
          IF sample = '1' THEN
            bit_index <= STD_LOGIC_VECTOR(shift_right(unsigned(bit_index), 1));
            data_i <= rx_ft & data_i(data_i'left DOWNTO 1);

            IF bit_index(0) = '1' THEN
              state <= Stop;
            END IF;
          END IF;
        WHEN Stop =>
          IF sample = '1' THEN
            IF rx_ft = '1' THEN
              state <= Idle;
              m_axis_tdata <= data_i;
              m_axis_tvalid <= '1';
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
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;