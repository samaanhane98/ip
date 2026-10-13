library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_packet_pkg.all;
use work.axis_pkg.all;
use work.array_pkg.all;

entity axis_packet_arbiter is
    generic (
        g_ports  : positive := 2;
        g_method : string   := "round_robin" -- round_robin, fixed
    );
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        packet_in        : in t_axis_packet_array(g_ports - 1 downto 0);
        packet_in_meta   : in t_vec_array(g_ports - 1 downto 0);
        packet_in_ready  : out std_logic_vector(g_ports - 1 downto 0);

        packet_out       : out t_axis_packet;
        packet_out_meta  : out std_logic_vector;
        packet_out_ready : in std_logic
    );
end entity axis_packet_arbiter;

architecture structure of axis_packet_arbiter is
    subtype t_packet_stream is t_axis(tdata(get_size(packet_out) - 1 downto 0), tkeep(-1 downto 0), tuser(packet_out_meta'range));
    signal packet_stream_out : t_packet_stream;

    subtype t_stream_array is t_axis_array(g_ports - 1 downto 0)(tdata(packet_stream_out.tdata'range), tkeep(packet_stream_out.tkeep'range), tuser(packet_out_meta'range));
    signal packet_stream_in : t_stream_array;
begin

    p_assign_input : process (all)
    begin
        for index in 0 to g_ports - 1 loop
            packet_stream_in(index).tvalid <= packet_in(index).valid;
            packet_stream_in(index).tlast  <= packet_in(index).last;
            packet_stream_in(index).tdata  <= pack(packet_in(index));
            packet_stream_in(index).tuser  <= packet_in_meta(index);
        end loop;
    end process;

    i_axis_arbiter : entity work.axis_arbiter
        generic map(
            g_ports  => g_ports,
            g_method => g_method
        )
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => packet_stream_in,
            stream_in_ready  => packet_in_ready,
            stream_out       => packet_stream_out,
            stream_out_ready => packet_out_ready
        );

    p_assign_output : process (all)
    begin
        packet_out       <= unpack(packet_stream_out.tdata, packet_out);
        packet_out.valid <= packet_stream_out.tvalid;
        packet_out_meta  <= packet_stream_out.tuser;
    end process;
end architecture;