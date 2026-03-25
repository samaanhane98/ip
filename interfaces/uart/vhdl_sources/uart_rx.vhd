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

  SIGNAL baud_tick : STD_LOGIC;
  SIGNAL sample : STD_LOGIC;
  SIGNAL sample_count : INTEGER RANGE 0 TO 15;

  TYPE t_uart_state IS (Idle, Start, Data, Stop, Error);
  SIGNAL state : t_uart_state;

  SIGNAL rx_sync : STD_LOGIC;
  SIGNAL rx_sr : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL rx_filter : STD_LOGIC;

  SIGNAL data_i : STD_LOGIC_VECTOR(m_axis_tdata'RANGE);
  SIGNAL bit_index : STD_LOGIC_VECTOR(m_axis_tdata'RANGE);
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

  p_oversampling : PROCESS (clk)
    VARIABLE v_count : INTEGER := 0;
  BEGIN
    IF rising_edge(clk) THEN
      baud_tick <= '0';
      v_count := v_count + 1;

      IF v_count = c_baud_tick_period THEN
        baud_tick <= '1';
        v_count := 0;
      END IF;

      IF reset = '1' THEN
        v_count := 0;
      END IF;
    END IF;
  END PROCESS;

  p_filter : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      -- filtered output is majority out of 3
      rx_filter <= (rx_sr(0) AND rx_sr(1)) OR (rx_sr(1) AND rx_sr(2)) OR (rx_sr(0) AND rx_sr(2));

      IF baud_tick = '1' THEN
        rx_sr <= rx_sr(1 DOWNTO 0) & rx_sync;
      END IF;

      IF reset = '1' THEN
        rx_sr <= (OTHERS => '1');
      END IF;
    END IF;
  END PROCESS;

  p_align_samples : PROCESS (clk) BEGIN IF rising_edge(clk) THEN
    sample <= '0';
    IF baud_tick = '1' THEN
      IF state = Idle THEN
        sample_count <= 0;
      ELSIF state = Start THEN
        IF sample_count = 8 THEN
          sample <= '1';
          sample_count <= 0;
        ELSE
          sample_count <= sample_count + 1;
        END IF;
      ELSE
        IF sample_count = 15 THEN
          sample <= '1';
          sample_count <= 0;
        ELSE
          sample_count <= sample_count + 1;
        END IF;
      END IF;
    END IF;
    IF reset = '1' THEN
      sample_count <= 0;
    END IF;
  END IF;
END PROCESS;

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
        IF rx_filter = '0' THEN
          state <= Start;
        END IF;
      WHEN Start =>
        IF sample = '1' THEN
          IF rx_filter = '0' THEN
            bit_index(bit_index'left) <= '1';
            state <= Data;
          ELSE
            state <= Idle;
          END IF;
        END IF;
      WHEN Data =>
        IF sample = '1' THEN
          bit_index <= STD_LOGIC_VECTOR(shift_right(unsigned(bit_index), 1));
          data_i <= rx_filter & data_i(data_i'left DOWNTO 1);

          IF bit_index(0) = '1' THEN
            state <= Stop;
          END IF;
        END IF;
      WHEN Stop =>
        IF sample = '1' THEN
          IF rx_filter = '1' THEN
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