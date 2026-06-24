LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axis_pkg.ALL;
ENTITY stream_to_axis_pkg IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tlast : IN STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_tuser : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    stream_out : OUT t_axis_32;
    stream_out_ready : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE structure OF stream_to_axis_pkg IS
  SIGNAL first : STD_LOGIC;
BEGIN

  s_axis_tready <= stream_out_ready;
  stream_out.tvalid <= s_axis_tvalid;
  stream_out.tlast <= s_axis_tlast;
  stream_out.tdata <= s_axis_tdata;
  stream_out.tuser <= s_axis_tuser;

  p_delay_tlast : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF s_axis_tready = '1' AND s_axis_tvalid = '1' THEN
        first <= s_axis_tlast;
      END IF;

      IF reset = '1' THEN
        first <= '0';
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;