library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_pkg.all;

entity axis_switch_dut is
    generic (
        g_ports : positive := 4
    );
    port (
        clk                : in std_logic;
        reset              : in std_logic;

        select_output      : in natural;

        stream_in          : in t_axis_32;
        stream_in_ready    : out std_logic;

        stream_out_0       : out t_axis_32;
        stream_out_0_ready : in std_logic;

        stream_out_1       : out t_axis_32;
        stream_out_1_ready : in std_logic;

        stream_out_2       : out t_axis_32;
        stream_out_2_ready : in std_logic;

        stream_out_3       : out t_axis_32;
        stream_out_3_ready : in std_logic
    );
end entity axis_switch_dut;

architecture structure of axis_switch_dut is
    signal streams_out : t_axis_32_array(3 downto 0);
    signal readys_out  : std_logic_vector(3 downto 0);
begin
    i_dut : entity work.axis_switch
        generic map(
            g_ports => g_ports
        )
        port map(
            clk              => clk,
            reset            => reset,
            select_output    => select_output,
            stream_in        => stream_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => streams_out,
            stream_out_ready => readys_out
        );

    stream_out_0      <= streams_out(0);
    readys_out(0)     <= stream_out_0_ready;

    stream_out_1      <= streams_out(1);
    readys_out(1)     <= stream_out_1_ready;

    stream_out_2      <= streams_out(2);
    readys_out(2)     <= stream_out_2_ready;

    stream_out_3      <= streams_out(3);
    readys_out(3)     <= stream_out_3_ready;
    
end architecture structure;