library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_packet_pkg.all;
use work.axis_pkg.all;
use work.vec_pkg.all;

entity axis_packet_switch is
    generic (
        g_ports : positive := 2
    );
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        select_output    : in natural;

        packet_in        : in t_axis_packet;
        packet_in_meta   : in std_logic_vector;
        packet_in_ready  : out std_logic;

        packet_out       : out t_axis_packet_array(g_ports - 1 downto 0);
        packet_out_meta  : out t_vec_array(g_ports - 1 downto 0);
        packet_out_ready : in std_logic_vector(g_ports - 1 downto 0)
    );
end entity axis_packet_switch;

architecture structure of axis_packet_switch is
    subtype t_packet_stream is t_axis(tdata(get_size(packet_in) - 1 downto 0), tkeep(-1 downto 0), tuser(packet_in_meta'range));
    signal packet_stream_in  : t_packet_stream;

    subtype t_stream_array is t_axis_array(g_ports - 1 downto 0)(tdata(packet_stream_in.tdata'range), tkeep(packet_stream_in.tkeep'range), tuser(packet_in_meta'range));
    signal packet_stream_out : t_stream_array;
begin
    packet_stream_in.tvalid <= packet_in.valid;
    packet_stream_in.tlast  <= packet_in.last;
    packet_stream_in.tdata  <= pack(packet_in);
    packet_stream_in.tuser  <= packet_in_meta;

    i_axis_switch : entity work.axis_switch
        generic map(
            g_ports => g_ports
        )
        port map(
            clk              => clk,
            reset            => reset,
            select_output    => select_output,
            stream_in        => packet_stream_in,
            stream_in_ready  => packet_in_ready,
            stream_out       => packet_stream_out,
            stream_out_ready => packet_out_ready
        );

    p_assign_output: process (all)
    begin
        for index in 0 to g_ports - 1 loop
            packet_out(index) <= unpack(packet_stream_out(index).tdata, packet_out(index));
            packet_out(index).valid <= packet_stream_out(index).tvalid;
            packet_out_meta(index) <= packet_stream_out(index).tuser;
        end loop;
    end process;
end architecture;