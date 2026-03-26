LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY uart_sample_gen IS
  GENERIC (
    g_clock_frequency : INTEGER := 100000000;
    g_baud_rate : INTEGER := 115200;
    g_data_bits : INTEGER := 8;
    g_stop_bits : INTEGER := 1;
    g_include_first_bit : BOOLEAN := true
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    ena : IN STD_LOGIC;

    baud_tick : BUFFER STD_LOGIC;
    sample : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE behavior OF uart_sample_gen IS
  CONSTANT c_bit_period : INTEGER := g_clock_frequency / g_baud_rate;
  CONSTANT c_baud_tick_period : INTEGER := c_bit_period / 16;

  SIGNAL sample_count : INTEGER RANGE 0 TO 16;

  SIGNAL first_bit : BOOLEAN;
BEGIN
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

  p_align_samples : PROCESS (clk) BEGIN IF rising_edge(clk) THEN
    sample <= '0';
    IF baud_tick = '1' THEN

      IF ena = '1' THEN
        sample_count <= sample_count + 1;
        IF first_bit THEN
          IF sample_count = 8 THEN
            sample <= '1';
            sample_count <= 0;
            first_bit <= false;
          END IF;
        ELSE
          IF sample_count = 15 THEN
            sample <= '1';
            sample_count <= 0;
          END IF;
        END IF;

      ELSE
        sample_count <= 0;
        first_bit <= g_include_first_bit;
      END IF;
    END IF;
    IF reset = '1' THEN
      sample_count <= 0;
      first_bit <= g_include_first_bit;
    END IF;
  END IF;
END PROCESS;

END ARCHITECTURE behavior;