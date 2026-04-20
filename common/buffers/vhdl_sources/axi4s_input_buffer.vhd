LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axi4s_pkg.ALL;

-- https://pavel-demin.github.io/red-pitaya-notes/axi-interface-buffers/
ENTITY axi4s_input_buffer IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    stream_in : IN t_axi4s_32;
    stream_in_ready : OUT STD_LOGIC;

    stream_out : OUT t_axi4s_32;
    stream_out_ready : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE behavior OF axi4s_input_buffer IS
  SIGNAL valid : STD_LOGIC;
  SIGNAL reg_in_tready : STD_LOGIC;
  SIGNAL reg_in_tlast : STD_LOGIC;
  SIGNAL reg_in_tdata : STD_LOGIC_VECTOR(stream_in.tdata'RANGE);
  SIGNAL reg_in_tuser : STD_LOGIC_VECTOR(stream_in.tuser'RANGE);
  SIGNAL reg_in_tkeep : STD_LOGIC_VECTOR(stream_in.tkeep'RANGE);

BEGIN
  stream_in_ready <= reg_in_tready;

  valid <= stream_in.tvalid OR NOT reg_in_tready;
  p_input_reg : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF stream_in.tvalid = '1' AND reg_in_tready = '1' THEN
        reg_in_tlast <= stream_in.tlast;
        reg_in_tdata <= stream_in.tdata;
        reg_in_tuser <= stream_in.tuser;
        reg_in_tkeep <= stream_in.tkeep;
      END IF;

      IF valid = '1' THEN
        reg_in_tready <= stream_out_ready;
      END IF;

      IF reset = '1' THEN
        reg_in_tready <= '1';
        reg_in_tlast <= '0';
        reg_in_tdata <= (OTHERS => '0');
        reg_in_tuser <= (OTHERS => '0');
        reg_in_tkeep <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  stream_out.tvalid <= valid;
  p_output_mux : PROCESS (ALL)
  BEGIN
    IF reg_in_tready = '1' THEN
      stream_out.tlast <= stream_in.tlast;
      stream_out.tdata <= stream_in.tdata;
      stream_out.tuser <= stream_in.tuser;
      stream_out.tkeep <= stream_in.tkeep;
    ELSE
      stream_out.tlast <= reg_in_tlast;
      stream_out.tuser <= reg_in_tuser;
      stream_out.tkeep <= reg_in_tkeep;
    END IF;
  END PROCESS;
END ARCHITECTURE;