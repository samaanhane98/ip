LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axi4s_bus_pkg.ALL;

-- https://pavel-demin.github.io/red-pitaya-notes/axi-interface-buffers/
ENTITY axi4s_input_buffer IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    packet_in : IN t_axi4s_packet_32;
    packet_in_ready : OUT STD_LOGIC;

    packet_out : OUT t_axi4s_packet_32;
    packet_out_ready : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE behavior OF axi4s_input_buffer IS
  SIGNAL valid : STD_LOGIC;
  SIGNAL reg_in_tready : STD_LOGIC;
  SIGNAL reg_in_tlast : STD_LOGIC;
  SIGNAL reg_in_tfirst : STD_LOGIC;
  SIGNAL reg_in_tdata : STD_LOGIC_VECTOR(packet_in.tdata'RANGE);
  SIGNAL reg_in_tuser : STD_LOGIC_VECTOR(packet_in.tuser'RANGE);
  SIGNAL reg_in_tkeep : STD_LOGIC_VECTOR(packet_in.tkeep'RANGE);

BEGIN
  packet_in_ready <= reg_in_tready;

  valid <= packet_in.tvalid OR NOT reg_in_tready;
  p_input_reg : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF packet_in.tvalid = '1' AND reg_in_tready = '1' THEN
        reg_in_tlast <= packet_in.tlast;
        reg_in_tfirst <= packet_in.tfirst;
        reg_in_tdata <= packet_in.tdata;
        reg_in_tuser <= packet_in.tuser;
        reg_in_tkeep <= packet_in.tkeep;
      END IF;

      IF valid = '1' THEN
        reg_in_tready <= packet_out_ready;
      END IF;

      IF reset = '1' THEN
        reg_in_tready <= '1';
        reg_in_tlast <= '0';
        reg_in_tfirst <= '0';
        reg_in_tdata <= (OTHERS => '0');
        reg_in_tuser <= (OTHERS => '0');
        reg_in_tkeep <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  packet_out.tvalid <= valid;
  p_output_mux : PROCESS (ALL)
  BEGIN
    IF reg_in_tready = '1' THEN
      packet_out.tlast <= packet_in.tlast;
      packet_out.tfirst <= packet_in.tfirst;
      packet_out.tdata <= packet_in.tdata;
      packet_out.tuser <= packet_in.tuser;
      packet_out.tkeep <= packet_in.tkeep;
    ELSE
      packet_out.tlast <= reg_in_tlast;
      packet_out.tfirst <= reg_in_tfirst;
      packet_out.tuser <= reg_in_tuser;
      packet_out.tkeep <= reg_in_tkeep;
    END IF;
  END PROCESS;
END ARCHITECTURE;