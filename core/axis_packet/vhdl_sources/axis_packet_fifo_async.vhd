library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;
    use work.axis_packet_pkg.all;
    use work.axis_pkg.all;

entity axis_packet_fifo_async is
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
        packet_in_clk           : in  std_logic;
        packet_in_reset         : in  std_logic;
        packet_in               : in  t_axis_packet;
        packet_in_meta          : in  std_logic_vector;
        packet_in_ready         : out std_logic;

        packet_out_clk          : in  std_logic;
        packet_out_reset        : in  std_logic;
        packet_out              : out t_axis_packet;
        packet_out_meta         : out std_logic_vector;
        packet_out_ready        : in  std_logic;

        packet_in_full          : out std_logic;
        packet_in_empty         : out std_logic;
        packet_in_almost_full   : out std_logic;
        packet_in_almost_empty  : out std_logic;
        packet_in_level         : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);

        packet_out_full         : out std_logic;
        packet_out_empty        : out std_logic;
        packet_out_almost_full  : out std_logic;
        packet_out_almost_empty : out std_logic;
        packet_out_level        : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0)
    );
end entity;

architecture structure of axis_packet_fifo_async is
    subtype t_packet_stream is t_axis(tdata(packet_in.data'range), tkeep(- 1 downto 0), tuser(packet_in_meta'range));
    signal packet_stream_in  : t_packet_stream;
    signal packet_stream_out : t_packet_stream;

    signal rd_valid : std_logic;
begin
    packet_stream_in.tvalid <= packet_in.valid;
    packet_stream_in.tlast  <= packet_in.last;
    packet_stream_in.tdata  <= pack(packet_in);
    packet_stream_in.tuser  <= packet_in_meta;

    i_axis_fifo_async: entity work.axis_fifo_async
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
            stream_in_clk           => packet_in_clk,
            stream_in_reset         => packet_in_reset,
            stream_in               => packet_stream_in,
            stream_in_ready         => packet_in_ready,
            stream_out_clk          => packet_out_clk,
            stream_out_reset        => packet_out_reset,
            stream_out              => packet_stream_out,
            stream_out_ready        => packet_out_ready,
            stream_in_full          => packet_in_full,
            stream_in_empty         => packet_in_empty,
            stream_in_almost_full   => packet_in_almost_full,
            stream_in_almost_empty  => packet_in_almost_empty,
            stream_in_level         => packet_in_level,
            stream_out_full         => packet_out_full,
            stream_out_empty        => packet_out_empty,
            stream_out_almost_full  => packet_out_almost_full,
            stream_out_almost_empty => packet_out_almost_empty,
            stream_out_level        => packet_out_level
        );

    packet_out      <= unpack(packet_stream_out.tdata, packet_out);
    packet_out_meta <= packet_stream_out.tuser;
end architecture;
