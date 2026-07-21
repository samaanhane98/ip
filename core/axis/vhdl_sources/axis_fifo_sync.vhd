library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use work.axis_pkg.all;

entity axis_fifo_sync is
    generic (
        g_implementation : string  := "auto";
        g_word_depth     : integer := 16 -- power of 2
    );
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        stream_in        : in  t_axis;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis;
        stream_out_ready : in  std_logic
    );
end entity;

architecture behavior of axis_fifo_sync is
    type t_ram_tdata is array (0 to g_word_depth - 1) of std_logic_vector(stream_in.tdata'RANGE);
    type t_ram_tuser is array (0 to g_word_depth - 1) of std_logic_vector(stream_in.tuser'RANGE);
    type t_ram_tkeep is array (0 to g_word_depth - 1) of std_logic_vector(stream_in.tkeep'RANGE);
    type t_ram_tlast is array (0 to g_word_depth - 1) of std_logic;
    type t_ram_tfirst is array (0 to g_word_depth - 1) of std_logic;
    signal ram_tdata : t_ram_tdata;
    signal ram_tuser : t_ram_tuser;
    signal ram_tkeep : t_ram_tkeep;
    signal ram_tlast : t_ram_tlast;

    attribute ram_style              : string;
    attribute ram_style of ram_tdata : signal is g_implementation;
    attribute ram_style of ram_tuser : signal is g_implementation;
    attribute ram_style of ram_tkeep : signal is g_implementation;
    attribute ram_style of ram_tlast : signal is g_implementation;

    signal read_pointer  : unsigned(integer(log2(real(g_word_depth))) - 1 downto 0) := (others => '0');
    signal write_pointer : unsigned(integer(log2(real(g_word_depth))) - 1 downto 0) := (others => '0');

    signal full  : std_logic;
    signal empty : std_logic;
begin
    stream_in_ready <= not full;

    p_full_gen: process (write_pointer, read_pointer)
    begin
        full <= '0';
        if write_pointer + 1 = read_pointer then
            full <= '1';
        end if;
    end process;

    p_empty_gen: process (write_pointer, read_pointer)
    begin
        empty <= '0';
        if write_pointer = read_pointer then
            empty <= '1';
        end if;
    end process;

    p_write: process (clk)
    begin
        if rising_edge(clk) then
            if stream_in.tvalid = '1' and stream_in_ready = '1' then
                ram_tdata(to_integer(write_pointer)) <= stream_in.tdata;
                ram_tuser(to_integer(write_pointer)) <= stream_in.tuser;
                ram_tkeep(to_integer(write_pointer)) <= stream_in.tkeep;
                ram_tlast(to_integer(write_pointer)) <= stream_in.tlast;

                write_pointer <= write_pointer + 1;
            end if;

            if reset = '1' then
                write_pointer <= (others => '0');
            end if;
        end if;
    end process;

    p_read: process (clk)
    begin
        if rising_edge(clk) then
            stream_out.tvalid <= not empty;
            stream_out.tdata <= ram_tdata(to_integer(read_pointer));
            stream_out.tuser <= ram_tuser(to_integer(read_pointer));
            stream_out.tkeep <= ram_tkeep(to_integer(read_pointer));
            stream_out.tlast <= ram_tlast(to_integer(read_pointer));

            if stream_out_ready = '1' and empty = '0' then
                read_pointer <= read_pointer + 1;
            end if;
            if reset = '1' then
                stream_out.tvalid <= '0';
                read_pointer <= (others => '0');
            end if;
        end if;
    end process;

end architecture;
