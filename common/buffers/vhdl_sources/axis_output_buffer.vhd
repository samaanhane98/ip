LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axis_pkg.ALL;

-- https://pavel-demin.github.io/red-pitaya-notes/axi-interface-buffers/
ENTITY axis_output_buffer IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    stream_in : IN t_axis;
    stream_in_ready : OUT STD_LOGIC;

    stream_out : OUT t_axis;
    stream_out_ready : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE behavior OF axis_output_buffer IS
  SIGNAL valid : STD_LOGIC;
  SIGNAL reg_in_tvalid : STD_LOGIC;
  SIGNAL reg_in_tlast : STD_LOGIC;
  SIGNAL reg_in_tfirst : STD_LOGIC;
  SIGNAL reg_in_tdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_in_tuser : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
  stream_in_ready <= (NOT reg_in_tvalid OR stream_out_ready);

  stream_out.tvalid <= reg_in_tvalid;
  stream_out.tlast <= reg_in_tlast;
  stream_out.tdata <= reg_in_tdata;
  stream_out.tuser <= reg_in_tuser;

  p_input_reg : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF stream_in.tvalid = '1' AND (reg_in_tvalid = '0' OR stream_out_ready = '1') THEN
        reg_in_tvalid <= stream_in.tvalid;
        reg_in_tlast <= stream_in.tlast;
        reg_in_tdata <= stream_in.tdata;
        reg_in_tuser <= stream_in.tuser;
      END IF;
      IF reset = '1' THEN
        reg_in_tvalid <= '0';
        reg_in_tlast <= '0';
        reg_in_tfirst <= '0';
        reg_in_tdata <= (OTHERS => '0');
        reg_in_tuser <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;