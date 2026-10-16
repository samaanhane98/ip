library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_pkg.all;

entity axis_input_latch_dut is
    generic (
        g_ports : positive := 4
    );
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        stream_in        : in t_axis_32;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis_32;
        stream_out_ready : in std_logic

    );
end entity axis_input_latch_dut;

architecture structure of axis_input_latch_dut is
begin
    i_dut : entity work.axis_input_latch
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => stream_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => stream_out,
            stream_out_ready => stream_out_ready
        );
end architecture structure;