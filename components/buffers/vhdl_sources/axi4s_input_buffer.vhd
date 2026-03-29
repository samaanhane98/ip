LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axi4s_bus.ALL;

-- https://pavel-demin.github.io/red-pitaya-notes/axi-interface-buffers/
ENTITY axi4s_input_buffer IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    stream_in_m2s : IN t_axi4s_m2s_32;
    stream_in_s2m : OUT t_axi4s_s2m;

    stream_out_m2s : OUT t_axi4s_m2s_32;
    stream_out_s2m : IN t_axi4s_s2m
  );
END ENTITY;

ARCHITECTURE behavior OF axi4s_input_buffer IS
  SIGNAL valid : STD_LOGIC;
  SIGNAL reg_in_tready : STD_LOGIC;
  SIGNAL reg_in_tlast : STD_LOGIC;
  SIGNAL reg_in_tfirst : STD_LOGIC;
  SIGNAL reg_in_tdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_in_tuser : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
  stream_in_s2m.tready <= reg_in_tready;

  valid <= stream_in_m2s.tvalid OR NOT reg_in_tready;
  p_input_reg : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF stream_in_m2s.tvalid = '1' AND reg_in_tready = '1' THEN
        reg_in_tlast <= stream_in_m2s.tlast;
        reg_in_tfirst <= stream_in_m2s.tfirst;
        reg_in_tdata <= stream_in_m2s.tdata;
        reg_in_tuser <= stream_in_m2s.tuser;
      END IF;

      IF valid = '1' THEN
        reg_in_tready <= stream_out_s2m.tready;
      END IF;

      IF reset = '1' THEN
        reg_in_tready <= '1';
        reg_in_tlast <= '0';
        reg_in_tfirst <= '0';
        reg_in_tdata <= (OTHERS => '0');
        reg_in_tuser <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  stream_out_m2s.tvalid <= valid;
  p_output_mux : PROCESS (ALL)
  BEGIN
    IF reg_in_tready = '1' THEN
      stream_out_m2s.tlast <= stream_in_m2s.tlast;
      stream_out_m2s.tfirst <= stream_in_m2s.tfirst;
      stream_out_m2s.tdata <= stream_in_m2s.tdata;
      stream_out_m2s.tuser <= stream_in_m2s.tuser;
    ELSE
      stream_out_m2s.tlast <= reg_in_tlast;
      stream_out_m2s.tfirst <= reg_in_tfirst;
      stream_out_m2s.tuser <= reg_in_tuser;
    END IF;
  END PROCESS;
END ARCHITECTURE;