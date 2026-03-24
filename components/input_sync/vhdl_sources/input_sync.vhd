LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY input_sync IS
  GENERIC (
    g_sync_stages : INTEGER RANGE 2 TO 16 := 2;
    g_reset_val : STD_LOGIC := '0'
  );
  PORT (
    input : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    dest_clk : IN STD_LOGIC;
    output : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE behavior OF input_sync IS
  SIGNAL output_sr : STD_LOGIC_VECTOR(g_sync_stages - 1 DOWNTO 0) := (OTHERS => g_reset_val);

  ATTRIBUTE ASYNC_REG : STRING;
  ATTRIBUTE ASYNC_REG OF output_sr : SIGNAL IS "TRUE";
BEGIN
  output <= output_sr(output_sr'high);

  p_reg : PROCESS (dest_clk)
  BEGIN
    IF rising_edge(dest_clk) THEN
      output_sr <= output_sr(output_sr'high - 1 DOWNTO 0) & input;

      IF reset = '1' THEN
        output_sr <= (OTHERS => g_reset_val);
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;