library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axis_packet_pkg.all;
use work.math_pkg.all;
use work.axis_pkg.all;
use work.array_pkg.all;

entity axis_packet_arbiter_dut is
    generic (
        g_ports  : positive := 4;
        g_method : string   := "round_robin" -- round_robin, fixed
    );
    port (
        clk               : in std_logic;
        reset             : in std_logic;

        packet_in_0       : in t_axis_packet_32;
        packet_in_0_meta  : in std_logic_vector(31 downto 0);
        packet_in_0_ready : out std_logic;

        packet_in_1       : in t_axis_packet_32;
        packet_in_1_meta  : in std_logic_vector(31 downto 0);
        packet_in_1_ready : out std_logic;

        packet_in_2       : in t_axis_packet_32;
        packet_in_2_meta  : in std_logic_vector(31 downto 0);
        packet_in_2_ready : out std_logic;

        packet_in_3       : in t_axis_packet_32;
        packet_in_3_meta  : in std_logic_vector(31 downto 0);
        packet_in_3_ready : out std_logic;

        packet_out        : out t_axis_packet_32;
        packet_out_meta   : out std_logic_vector(31 downto 0);
        packet_out_ready  : in std_logic
    );
end entity axis_packet_arbiter_dut;

architecture structure of axis_packet_arbiter_dut is
    signal packets_in : t_axis_packet_32_array(3 downto 0);
    signal metas_in   : t_vec_array_32(3 downto 0);
    signal readys_in  : std_logic_vector(3 downto 0);
begin
    packets_in(0) <= packet_in_0;
    metas_in(0)   <= packet_in_0_meta;
    packet_in_0_ready <= readys_in(0);

    packets_in(1) <= packet_in_1;
    metas_in(1)   <= packet_in_1_meta;
    packet_in_1_ready <= readys_in(1);

    packets_in(2) <= packet_in_2;
    metas_in(2)   <= packet_in_2_meta;
    packet_in_2_ready <= readys_in(2);

    packets_in(3) <= packet_in_3;
    metas_in(3)   <= packet_in_3_meta;
    packet_in_3_ready <= readys_in(3);

    i_axis_packet_arbiter : entity work.axis_packet_arbiter
        generic map(
            g_ports  => g_ports,
            g_method => g_method
        )
        port map(
            clk              => clk,
            reset            => reset,
            packet_in        => packets_in,
            packet_in_meta   => metas_in,
            packet_in_ready  => readys_in,
            packet_out       => packet_out,
            packet_out_meta  => packet_out_meta,
            packet_out_ready => packet_out_ready
        );
end architecture structure;