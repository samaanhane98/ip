LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

USE work.axi4s_bus_pkg.ALL;

-- https://pavel-demin.github.io/red-pitaya-notes/axi-interface-buffers/
ENTITY axi4s_output_buffer IS
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    packet_in : IN t_axi4s_packet_32;
    packet_in_ready : OUT STD_LOGIC;

    packet_out : OUT t_axi4s_packet_32;
    packet_out_ready : IN STD_LOGIC
  );
END ENTITY;

ARCHITECTURE behavior OF axi4s_output_buffer IS
  SIGNAL valid : STD_LOGIC;
  SIGNAL reg_in_tvalid : STD_LOGIC;
  SIGNAL reg_in_tlast : STD_LOGIC;
  SIGNAL reg_in_tfirst : STD_LOGIC;
  SIGNAL reg_in_tdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL reg_in_tuser : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
  packet_in_ready <= (NOT reg_in_tvalid OR packet_out_ready);

  packet_out.tvalid <= reg_in_tvalid;
  packet_out.tlast <= reg_in_tlast;
  packet_out.tfirst <= reg_in_tfirst;
  packet_out.tdata <= reg_in_tdata;
  packet_out.tuser <= reg_in_tuser;

  p_input_reg : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF packet_in.tvalid = '1' AND (reg_in_tvalid = '0' OR packet_out_ready = '1') THEN
        reg_in_tvalid <= packet_in.tvalid;
        reg_in_tlast <= packet_in.tlast;
        reg_in_tfirst <= packet_in.tfirst;
        reg_in_tdata <= packet_in.tdata;
        reg_in_tuser <= packet_in.tuser;
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