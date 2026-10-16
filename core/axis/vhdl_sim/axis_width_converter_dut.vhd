library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_pkg.all;

entity axis_width_converter_dut is
    generic (
        g_ports : positive := 4
    );
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        stream_in        : in t_axis_8;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis_16;
        stream_out_ready : in std_logic

    );
end entity axis_width_converter_dut;

architecture structure of axis_width_converter_dut is

    signal stream_mid        : t_axis_128;
    signal stream_mid_ready  : std_logic;
begin
    i_stage_0 : entity work.axis_width_converter
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => stream_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => stream_mid,
            stream_out_ready => stream_mid_ready
        );

    i_stage_1 : entity work.axis_width_converter
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => stream_mid,
            stream_in_ready  => stream_mid_ready,
            stream_out       => stream_out,
            stream_out_ready => stream_out_ready
        );
end architecture structure;