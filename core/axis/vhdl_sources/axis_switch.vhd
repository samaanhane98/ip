library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_pkg.all;

entity axis_switch is
    generic (
        g_ports : positive := 2
    );
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        select_output    : in natural;

        stream_in        : in t_axis;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis_array(g_ports - 1 downto 0);
        stream_out_ready : in std_logic_vector(g_ports - 1 downto 0)
    );
end entity axis_switch;

architecture behavior of axis_switch is
begin

    p_set_output : process (all)
    begin
        for index in g_ports - 1 downto 0 loop
            if index = select_output then
                stream_out(index)   <= stream_in;
                stream_in_ready     <= stream_out_ready(index);
            else
                stream_out(index).tvalid <= '0';
            end if;
        end loop;
    end process;
end architecture behavior;