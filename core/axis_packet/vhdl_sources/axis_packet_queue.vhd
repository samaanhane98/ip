library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_packet_pkg.all;
use work.axis_pkg.all;
use work.array_pkg.all;

entity axis_packet_queue is
    generic (
        g_ports : positive := 2
    );
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        packet_in        : in t_axis_packet;
        packet_in_meta   : in std_logic_vector;
        packet_in_ready  : out std_logic;

        packet_out       : out t_axis_packet;
        packet_out_meta  : out std_logic_vector;
        packet_out_ready : in std_logic
    );
end entity axis_packet_queue;

architecture structure of axis_packet_queue is
    begin
    end architecture;