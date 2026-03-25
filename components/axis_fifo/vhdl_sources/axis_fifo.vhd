LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY axis_fifo IS
  GENERIC (
    g_word_depth : INTEGER := 16; -- power of 2
    g_tdata_width : INTEGER := 32;
    g_tuser_width : INTEGER := 8
  );
  PORT (
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;

    s_axis_tvalid : IN STD_LOGIC;
    s_axis_tready : OUT STD_LOGIC;
    s_axis_tlast : IN STD_LOGIC;
    s_axis_tdata : IN STD_LOGIC_VECTOR(g_tdata_width - 1 DOWNTO 0);
    s_axis_tuser : IN STD_LOGIC_VECTOR(g_tuser_width - 1 DOWNTO 0);

    m_axis_tvalid : OUT STD_LOGIC;
    m_axis_tready : IN STD_LOGIC;
    m_axis_tlast : OUT STD_LOGIC;
    m_axis_tdata : OUT STD_LOGIC_VECTOR(g_tdata_width - 1 DOWNTO 0);
    m_axis_tuser : OUT STD_LOGIC_VECTOR(g_tuser_width - 1 DOWNTO 0)

  );
END ENTITY;

ARCHITECTURE behavior OF axis_fifo IS
  TYPE t_ram_tdata IS ARRAY (0 TO g_word_depth - 1) OF STD_LOGIC_VECTOR(s_axis_tdata'RANGE);
  TYPE t_ram_tuser IS ARRAY (0 TO g_word_depth - 1) OF STD_LOGIC_VECTOR(s_axis_tuser'RANGE);
  TYPE t_ram_tlast IS ARRAY (0 TO g_word_depth - 1) OF STD_LOGIC;
  SIGNAL ram_tdata : t_ram_tdata;
  SIGNAL ram_tuser : t_ram_tuser;
  SIGNAL ram_tlast : t_ram_tlast;

  SIGNAL read_pointer : UNSIGNED(INTEGER(log2(real(g_word_depth))) - 1 DOWNTO 0);
  SIGNAL write_pointer : UNSIGNED(INTEGER(log2(real(g_word_depth))) - 1 DOWNTO 0);

  SIGNAL s_tready : STD_LOGIC := '1';

  SIGNAL full : STD_LOGIC;
  SIGNAL empty : STD_LOGIC;
BEGIN
  s_tready <= NOT full;
  s_axis_tready <= s_tready;

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
      IF s_axis_tvalid = '1' AND s_tready = '1' THEN
        ram_tdata(to_integer(write_pointer)) <= s_axis_tdata;
        ram_tuser(to_integer(write_pointer)) <= s_axis_tuser;
        ram_tlast(to_integer(write_pointer)) <= s_axis_tlast;

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
      m_axis_tvalid <= NOT empty;
      m_axis_tdata <= ram_tdata(to_integer(read_pointer));
      m_axis_tuser <= ram_tuser(to_integer(read_pointer));
      m_axis_tlast <= ram_tlast(to_integer(read_pointer));

      IF m_axis_tready = '1' AND empty = '0' THEN
        read_pointer <= read_pointer + 1;
      END IF;
      IF reset = '1' THEN
        m_axis_tvalid <= '0';
        read_pointer <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE behavior;