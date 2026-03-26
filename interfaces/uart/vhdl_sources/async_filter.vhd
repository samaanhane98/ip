LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY async_filter IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    sample_clk : IN STD_LOGIC;

    data_async : IN STD_LOGIC;
    data_ft : OUT STD_LOGIC
  );
END ENTITY;

ARCHITECTURE behavior OF async_filter IS
  SIGNAL data_sync : STD_LOGIC;
  SIGNAL data_sr : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN
  input_sync_inst : ENTITY work.input_sync
    GENERIC MAP(
      g_sync_stages => 2,
      g_reset_val => '1'
    )
    PORT MAP(
      input => data_async,
      reset => reset,
      dest_clk => clk,
      output => data_sync
    );

  p_filter : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      -- filtered output is majority out of 3
      data_ft <= (data_sr(0) AND data_sr(1)) OR (data_sr(1) AND data_sr(2)) OR (data_sr(0) AND data_sr(2));

      IF sample_clk = '1' THEN
        data_sr <= data_sr(1 DOWNTO 0) & data_sync;
      END IF;

      IF reset = '1' THEN
        data_sr <= (OTHERS => '1');
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE behavior;