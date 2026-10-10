library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_packet_pkg.all;
use work.axis_pkg.all;

entity axis_packet_fifo_async is
    generic (
        g_depth              : positive              := 32;
        g_almost_full_ena    : boolean               := false;
        g_almost_full_level  : natural               := 0;
        g_almost_empty_ena   : boolean               := false;
        g_almost_empty_level : natural               := 0;
        g_ram_style          : string                := "auto";
        g_ram_behavior       : string                := "RBW";
        g_ready_reset_state  : std_logic             := '1';
        g_optimization       : string                := "SPEED";
        g_sync_stages        : positive range 2 to 4 := 2
    );
    port (
        packet_in_clk    : in std_logic;
        packet_in_reset  : in std_logic;
        packet_in        : in t_axis_packet;
        packet_in_meta   : in std_logic_vector;
        packet_in_ready  : out std_logic;

        packet_out_clk   : in std_logic;
        packet_out_reset : in std_logic;
        packet_out       : out t_axis_packet;
        packet_out_meta  : out std_logic_vector;
        packet_out_ready : in std_logic;

        wr_full          : out std_logic;
        wr_empty         : out std_logic;
        wr_almost_full   : out std_logic;
        wr_almost_empty  : out std_logic;
        wr_level         : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);

        rd_full          : out std_logic;
        rd_empty         : out std_logic;
        rd_almost_full   : out std_logic;
        rd_almost_empty  : out std_logic;
        rd_level         : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0)
    );
end entity;

architecture structure of axis_packet_fifo_async is
    subtype t_packet_stream is t_axis(tdata(packet_in.data'range), tkeep(-1 downto 0), tuser(packet_in_meta'range));
    signal packet_stream_in  : t_packet_stream;
    signal packet_stream_out : t_packet_stream;

    signal rd_valid          : std_logic;
begin
    packet_stream_in.tvalid <= packet_in.valid;
    packet_stream_in.tlast  <= packet_in.last;
    packet_stream_in.tdata  <= pack(packet_in);
    packet_stream_in.tuser  <= packet_in_meta;

    i_axis_fifo_async : entity work.axis_fifo_async
        generic map(
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
        port map(
            stream_in_clk    => packet_in_clk,
            stream_in_reset  => packet_in_reset,
            stream_in        => packet_stream_in,
            stream_in_ready  => packet_in_ready,
            stream_out_clk   => packet_out_clk,
            stream_out_reset => packet_out_reset,
            stream_out       => packet_stream_out,
            stream_out_ready => packet_out_ready,
            wr_full          => wr_full,
            wr_empty         => wr_empty,
            wr_almost_full   => wr_almost_full,
            wr_almost_empty  => wr_almost_empty,
            wr_level         => wr_level,
            rd_full          => rd_full,
            rd_empty         => rd_empty,
            rd_almost_full   => rd_almost_full,
            rd_almost_empty  => rd_almost_empty,
            rd_level         => rd_level
        );

    p_set_output : process (all)
    begin
        packet_out       <= unpack(packet_stream_out.tdata, packet_out);
        packet_out.valid <= packet_stream_out.tvalid;
        packet_out_meta  <= packet_stream_out.tuser;
    end process;
end architecture;