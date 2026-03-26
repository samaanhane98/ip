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

    tx : OUT STD_LOGIC;

    s_axis_tdata : IN STD_LOGIC_VECTOR(g_data_bits - 1 DOWNTO 0);
    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE structure OF uart_tx IS
  CONSTANT c_bit_period : INTEGER := g_clock_frequency / g_baud_rate;

  TYPE t_uart_state IS (Idle, Send);
  SIGNAL state : t_uart_state := Idle;
  TYPE t_gen_state IS (Half, Full);
  SIGNAL gen_state : t_gen_state;

  SIGNAL sample_ena : STD_LOGIC;
  SIGNAL baud_tick : STD_LOGIC;
  SIGNAL sample : STD_LOGIC;

  SIGNAL ready : STD_LOGIC;
  SIGNAL data : STD_LOGIC_VECTOR(g_data_bits + g_stop_bits DOWNTO 0); -- start, data, stop
  SIGNAL bit_index : STD_LOGIC_VECTOR(data'RANGE);

BEGIN
  s_axis_tready <= '1' WHEN state = Idle ELSE
    '0';
  tx <= data(0);

  uart_sample_gen_inst : ENTITY work.uart_sample_gen
    GENERIC MAP(
      g_clock_frequency => g_clock_frequency,
      g_baud_rate => g_baud_rate,
      g_data_bits => g_data_bits,
      g_stop_bits => g_stop_bits,
      g_include_first_bit => false
    )
    PORT MAP(
      clk => clk,
      reset => reset,
      ena => sample_ena,
      baud_tick => baud_tick,
      sample => sample
    );
  sample_ena <= '0' WHEN state = Idle ELSE
    '1';

  p_state_machine : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      CASE state IS
        WHEN Idle =>
          IF s_axis_tvalid = '1' THEN
            data <= "1" & s_axis_tdata & "0";
            bit_index(bit_index'left) <= '1';
            state <= Send;
          END IF;
        WHEN Send =>
          IF sample = '1' THEN
            data <= STD_LOGIC_VECTOR(shift_right(unsigned(data), 1));
            bit_index <= STD_LOGIC_VECTOR(shift_right(unsigned(bit_index), 1));

            IF bit_index(0) = '1' THEN
              data <= (OTHERS => '1');
              bit_index <= (OTHERS => '0');
              state <= Idle;
            END IF;
          END IF;
      END CASE;
      IF reset = '1' THEN
        data <= (OTHERS => '1');
        bit_index <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;