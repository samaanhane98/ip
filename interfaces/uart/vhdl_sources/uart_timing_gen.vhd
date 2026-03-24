LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY uart_timing_gen IS
  GENERIC (
    g_clock_frequency : INTEGER := 100000000;
    g_baud_rate : INTEGER := 115200
  );
  PORT (
    clk : IN STD_LOGIC;
    ena : IN STD_LOGIC;

    bit_period2 : OUT STD_LOGIC;
    bit_period : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE behavior OF uart_timing_gen IS
  CONSTANT c_bit_period : INTEGER := g_clock_frequency / g_baud_rate;
  CONSTANT c_bit_period2 : INTEGER := g_clock_frequency / (2 * g_baud_rate);

  TYPE t_gen_state IS (Half, Full);
  SIGNAL state : t_gen_state;

  SIGNAL count : INTEGER := 0;
BEGIN

  p_timing_gen : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      bit_period <= '0';
      bit_period2 <= '0';
      IF ena = '1' THEN
        count <= count + 1;
        CASE state IS
          WHEN Half =>
            IF count = c_bit_period2 THEN
              bit_period2 <= '1';
              state <= Full;
              count <= 0;
            END IF;
          WHEN Full =>
            IF count = c_bit_period THEN
              bit_period <= '1';
              count <= 0;
            END IF;
        END CASE;
      ELSE
        state <= Half;
        count <= 0;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;