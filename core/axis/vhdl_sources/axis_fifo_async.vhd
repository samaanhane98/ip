library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;
    use work.axis_pkg.all;

entity axis_fifo_async is
    generic (
        g_depth              : POSITIVE              := 32;
        g_almost_full_ena    : BOOLEAN               := false;
        g_almost_full_level  : natural               := 0;
        g_almost_empty_ena   : BOOLEAN               := false;
        g_almost_empty_level : natural               := 0;
        g_ram_style          : string                := "auto";
        g_ram_behavior       : string                := "RBW";
        g_ready_reset_state  : STD_LOGIC             := '1';
        g_optimization       : string                := "SPEED";
        g_sync_stages        : POSITIVE range 2 to 4 := 2
    );
    port (
        stream_in_clk           : in  std_logic;
        stream_in_reset         : in  std_logic;
        stream_in               : in  t_axis;
        stream_in_ready         : out std_logic;

        stream_out_clk          : in  std_logic;
        stream_out_reset        : in  std_logic;
        stream_out              : out t_axis;
        stream_out_ready        : in  std_logic;

        stream_in_full          : out std_logic;
        stream_in_empty         : out std_logic;
        stream_in_almost_full   : out std_logic;
        stream_in_almost_empty  : out std_logic;
        stream_in_level         : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);

        stream_out_full         : out std_logic;
        stream_out_empty        : out std_logic;
        stream_out_almost_full  : out std_logic;
        stream_out_almost_empty : out std_logic;
        stream_out_level        : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0)
    );
end entity;

architecture structure of axis_fifo_async is
    signal stream_in_slv  : std_logic_vector(get_size(stream_in) - 1 downto 0);
    signal stream_out_slv : std_logic_vector(get_size(stream_out) - 1 downto 0);

    signal rd_valid : std_logic;
begin
    stream_in_slv <= pack(stream_in);

    i_fifo_sync: entity work.fifo_async
        generic map (
            g_depth              => g_depth,
            g_almost_full_ena    => g_almost_full_ena,
            g_almost_full_level  => g_almost_full_level,
            g_almost_empty_ena   => g_almost_empty_ena,
            g_almost_empty_level => g_almost_empty_level,
            g_ram_style          => g_ram_style,
            g_ram_behavior       => g_ram_behavior,
            g_ready_reset_state  => g_ready_reset_state,
            g_optimization       => g_optimization,
            g_sync_stages        => g_sync_stages
        )
        port map (
            wr_clk          => stream_in_clk,
            wr_reset        => stream_in_reset,

            wr_data         => stream_in_slv,
            wr_valid        => stream_in.tvalid,
            wr_ready        => stream_in_ready,

            rd_clk          => stream_out_clk,
            rd_reset        => stream_out_reset,
            rd_data         => stream_out_slv,
            rd_valid        => rd_valid,
            rd_ready        => stream_out_ready,

            wr_full         => stream_in_full,
            wr_empty        => stream_in_empty,
            wr_almost_full  => stream_in_almost_empty,
            wr_almost_empty => stream_in_almost_empty,
            wr_level        => stream_in_level,

            rd_full         => stream_out_full,
            rd_empty        => stream_out_empty,
            rd_almost_full  => stream_out_almost_full,
            rd_almost_empty => stream_out_almost_empty,
            rd_level        => stream_out_level
        );

    stream_out        <= unpack(stream_out_slv, stream_out);
    stream_out.tvalid <= rd_valid;
end architecture;
