library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_pkg.all;

entity axis_arbiter_dut is
    generic (
        g_ports : positive := 4
    );
    port (
        clk               : in std_logic;
        reset             : in std_logic;

        stream_in_0       : in t_axis_32;
        stream_in_0_ready : out std_logic;

        stream_in_1       : in t_axis_32;
        stream_in_1_ready : out std_logic;

        stream_in_2       : in t_axis_32;
        stream_in_2_ready : out std_logic;

        stream_in_3       : in t_axis_32;
        stream_in_3_ready : out std_logic;

        stream_out        : out t_axis_32;
        stream_out_ready  : in std_logic
    );
end entity axis_arbiter_dut;

architecture structure of axis_arbiter_dut is
    signal streams_in : t_axis_32_array(3 downto 0);
    signal readys_in  : std_logic_vector(3 downto 0);
begin
    streams_in(0)     <= stream_in_0;
    stream_in_0_ready <= readys_in(0);

    streams_in(1)     <= stream_in_1;
    stream_in_1_ready <= readys_in(1);

    streams_in(2)     <= stream_in_2;
    stream_in_2_ready <= readys_in(2);

    streams_in(3)     <= stream_in_3;
    stream_in_3_ready <= readys_in(3);

    i_axis_arbiter : entity work.axis_arbiter
        generic map(
            g_ports  => g_ports,
            g_method => "round_robin"
        )
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => streams_in,
            stream_in_ready  => readys_in,
            stream_out       => stream_out,
            stream_out_ready => stream_out_ready
        );
end architecture structure;