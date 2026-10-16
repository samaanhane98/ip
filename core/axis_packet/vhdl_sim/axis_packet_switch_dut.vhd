library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axis_packet_pkg.all;
use work.math_pkg.all;
use work.axis_pkg.all;
use work.vec_pkg.all;

entity axis_packet_switch_dut is
    generic (
        g_ports : positive := 4
    );
    port (
        clk                : in std_logic;
        reset              : in std_logic;

        select_output      : in natural;

        packet_in          : in t_axis_packet_32;
        packet_in_meta     : in std_logic_vector(31 downto 0);
        packet_in_ready    : out std_logic;

        packet_out_0       : out t_axis_packet_32;
        packet_out_0_meta  : out std_logic_vector(31 downto 0);
        packet_out_0_ready : in std_logic;

        packet_out_1       : out t_axis_packet_32;
        packet_out_1_meta  : out std_logic_vector(31 downto 0);
        packet_out_1_ready : in std_logic;

        packet_out_2       : out t_axis_packet_32;
        packet_out_2_meta  : out std_logic_vector(31 downto 0);
        packet_out_2_ready : in std_logic;

        packet_out_3       : out t_axis_packet_32;
        packet_out_3_meta  : out std_logic_vector(31 downto 0);
        packet_out_3_ready : in std_logic
    );
end entity axis_packet_switch_dut;

architecture structure of axis_packet_switch_dut is
    signal packets_out : t_axis_packet_32_array(3 downto 0);
    signal metas_out   : t_vec_array_32(3 downto 0);
    signal readys_out  : std_logic_vector(3 downto 0);
begin

    i_axis_packet_switch : entity work.axis_packet_switch
        generic map(
            g_ports => g_ports
        )
        port map(
            clk              => clk,
            reset            => reset,
            select_output    => select_output,
            packet_in        => packet_in,
            packet_in_meta   => packet_in_meta,
            packet_in_ready  => packet_in_ready,
            packet_out       => packets_out,
            packet_out_meta  => metas_out,
            packet_out_ready => readys_out
        );

    packet_out_0      <= packets_out(0);
    packet_out_0_meta <= metas_out(0);
    readys_out(0)     <= packet_out_0_ready;

    packet_out_1      <= packets_out(1);
    packet_out_1_meta <= metas_out(1);
    readys_out(1)     <= packet_out_1_ready;

    packet_out_2      <= packets_out(2);
    packet_out_2_meta <= metas_out(2);
    readys_out(2)     <= packet_out_2_ready;

    packet_out_3      <= packets_out(3);
    packet_out_3_meta <= metas_out(3);
    readys_out(3)     <= packet_out_3_ready;

end architecture structure;