library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vec_pkg.all;

entity clock_and_reset_bfm is
    generic (
        g_periods : t_real_array;
        g_resets  : t_natural_array
    );
    port (
        clock_out : out std_logic_vector(g_periods'range);
        reset_out : out std_logic_vector(g_resets'range)
    );
end entity;

architecture behavior of clock_and_reset_bfm is
begin
    assert g_periods'length = g_resets'length report "Error: generics do not have the same length";

    g_clock_reset : for index in g_periods'range generate
        b_clock                : block
            constant c_full_period : time := g_periods(index) * 1 ns;
            constant c_half_period: time := c_full_period / 2;
        begin
            assert c_half_period > 0 ps
            report "Clock " & integer'image(index) &
                ": half period is zero (period list value = " &
                real'image(g_periods(index)) & ")"
                severity failure;

            p_generate : process
            begin
                clock_out(index) <= '0';
                wait for c_half_period;
                clock_out(index) <= '1';
                wait for c_half_period;
            end process;
        end block;

        b_reset : block
            constant c_reset_time: time := g_resets(index) * 1 ns;
        begin
            p_generate: process
            begin
                reset_out(index) <= '1';
                wait for c_reset_time;
                reset_out(index) <= '0';
                wait;
            end process;
        end block;
    end generate;
end architecture;