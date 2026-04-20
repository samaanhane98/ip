LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

USE work.axi4s_bus_pkg.ALL;

ENTITY axis_fifo IS
  GENERIC (
    g_word_depth : INTEGER := 16 -- power of 2
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    packet_in : IN t_axi4s_packet_32;
    packet_in_ready : OUT STD_LOGIC;

    packet_out : OUT t_axi4s_packet_32;
    packet_out_ready : IN STD_LOGIC
  );
END ENTITY;

-- TODO: make sure this synthesizes to bram
ARCHITECTURE behavior OF axis_fifo IS
  TYPE t_ram_tdata IS ARRAY (0 TO g_word_depth - 1) OF STD_LOGIC_VECTOR(packet_in.tdata'RANGE);
  TYPE t_ram_tuser IS ARRAY (0 TO g_word_depth - 1) OF STD_LOGIC_VECTOR(packet_in.tuser'RANGE);
  TYPE t_ram_tkeep IS ARRAY (0 TO g_word_depth - 1) OF STD_LOGIC_VECTOR(packet_in.tuser'RANGE);
  TYPE t_ram_tlast IS ARRAY (0 TO g_word_depth - 1) OF STD_LOGIC;
  TYPE t_ram_tfirst IS ARRAY (0 TO g_word_depth - 1) OF STD_LOGIC;
  SIGNAL ram_tdata : t_ram_tdata;
  SIGNAL ram_tuser : t_ram_tuser;
  SIGNAL ram_tkeep : t_ram_tkeep;
  SIGNAL ram_tlast : t_ram_tlast;
  SIGNAL ram_tfirst : t_ram_tlast;

  ATTRIBUTE ram_style : STRING;
  ATTRIBUTE ram_style OF ram_tdata : SIGNAL IS "block";
  ATTRIBUTE ram_style OF ram_tuser : SIGNAL IS "block";
  ATTRIBUTE ram_style OF ram_tkeep : SIGNAL IS "block";
  ATTRIBUTE ram_style OF ram_tlast : SIGNAL IS "block";
  ATTRIBUTE ram_style OF ram_tfirst : SIGNAL IS "block";

  SIGNAL read_pointer : UNSIGNED(INTEGER(log2(real(g_word_depth))) - 1 DOWNTO 0);
  SIGNAL write_pointer : UNSIGNED(INTEGER(log2(real(g_word_depth))) - 1 DOWNTO 0);

  SIGNAL s_tready : STD_LOGIC := '1';

  SIGNAL full : STD_LOGIC;
  SIGNAL empty : STD_LOGIC;
BEGIN
  s_tready <= NOT full;
  packet_in_ready <= s_tready;

  p_full_gen : PROCESS (write_pointer, read_pointer, reset)
  BEGIN
    full <= '0';
    IF write_pointer + 1 = read_pointer THEN
      full <= '1';
    END IF;

    IF reset = '1' THEN
      full <= '0';
    END IF;
  END PROCESS;

  p_empty_gen : PROCESS (write_pointer, read_pointer, reset)
  BEGIN
    empty <= '0';
    IF write_pointer = read_pointer THEN
      empty <= '1';
    END IF;

    IF reset = '1' THEN
      empty <= '1';
    END IF;
  END PROCESS;

  p_write : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF packet_in.tvalid = '1' AND s_tready = '1' THEN
        ram_tdata(to_integer(write_pointer)) <= packet_in.tdata;
        ram_tuser(to_integer(write_pointer)) <= packet_in.tuser;
        ram_tkeep(to_integer(write_pointer)) <= packet_in.tkeep;
        ram_tlast(to_integer(write_pointer)) <= packet_in.tlast;
        ram_tfirst(to_integer(write_pointer)) <= packet_in.tfirst;

        write_pointer <= write_pointer + 1;
      END IF;

      IF reset = '1' THEN
        write_pointer <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

  p_read : PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      packet_out.tvalid <= NOT empty;
      packet_out.tdata <= ram_tdata(to_integer(read_pointer));
      packet_out.tuser <= ram_tuser(to_integer(read_pointer));
      packet_out.tkeep <= ram_tkeep(to_integer(read_pointer));
      packet_out.tlast <= ram_tlast(to_integer(read_pointer));
      packet_out.tfirst <= ram_tfirst(to_integer(read_pointer));

      IF packet_out_ready = '1' AND empty = '0' THEN
        read_pointer <= read_pointer + 1;
      END IF;
      IF reset = '1' THEN
        packet_out.tvalid <= '0';
        read_pointer <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE behavior;