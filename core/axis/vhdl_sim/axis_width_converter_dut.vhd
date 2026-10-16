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

        stream_out       : out t_axis_32;
        stream_out_ready : in std_logic

    );
end entity axis_width_converter_dut;

architecture structure of axis_width_converter_dut is
begin
    i_dut : entity work.axis_width_converter
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => stream_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => stream_out,
            stream_out_ready => stream_out_ready
        );
end architecture structure;