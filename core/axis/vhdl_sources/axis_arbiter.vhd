library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.axis_pkg.all;
use work.vec_pkg.all;

entity axis_arbiter is
    generic (
        g_ports  : natural := 2;
        g_method : string  := "round_robin" -- round_robin, fixed
    );
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        stream_in        : in t_axis_array(g_ports - 1 downto 0);
        stream_in_ready  : out std_logic_vector(g_ports - 1 downto 0);

        stream_out       : out t_axis;
        stream_out_ready : in std_logic
    );
end entity axis_arbiter;

architecture behavior of axis_arbiter is
    function get_valids(streams : stream_in'subtype) return std_logic_vector is
        variable v_valids           : std_logic_vector(streams'range);
    begin
        v_valids := (others => '0');
        for index in streams'range loop
            v_valids(index) := streams(index).tvalid;
        end loop;
        return v_valids;
    end function;

    function round_robin(current : natural; streams : stream_in'subtype) return natural is
        variable v_valids         : std_logic_vector(streams'range);
        variable v_ordered_valids : std_logic_vector(streams'range);
        variable v_result         : natural;
    begin
        v_result         := 0;
        v_valids         := get_valids(streams);

        v_ordered_valids := v_valids(current downto 0) & v_valids(v_valids'left downto current + 1);

        for index in v_ordered_valids'range loop
            if v_ordered_valids(index) = '1' then
                v_result := (current + index + 1) mod streams'length;
            end if;
        end loop;

        return v_result;
    end function;

    function fixed(streams : stream_in'subtype) return natural is
        variable v_result      : natural;
    begin
        v_result := 0;
        for index in streams'range loop
            if streams(index).tvalid = '1' then
                v_result := index;
            end if;
        end loop;
        return v_result;
    end function;

    function schedule(current : natural; streams : stream_in'subtype; method : string) return natural is
    begin
        if method = "round_robin" then
            return round_robin(current, streams);
        elsif method = "fixed" then
            return fixed(streams);
        else
            return 0;
        end if;
    end function;

    type t_state is (Idle, Active);
    signal state           : t_state;

    signal current_output  : natural;
    signal selected_output : natural;
begin
    selected_output <= schedule(current_output, stream_in, g_method);

    p_set_output : process (all)
    begin
        stream_in_ready <= (others => '0');

        case state is
            when Idle =>
                stream_out                       <= stream_in(selected_output);
                stream_in_ready(selected_output) <= stream_out_ready;
            when Active =>
                stream_out                      <= stream_in(current_output);
                stream_in_ready(current_output) <= stream_out_ready;
        end case;
    end process;

    p_schedule : process (clk)
    begin
        if rising_edge(clk) then
            case state is
                when Idle =>
                    if or_reduce(get_valids(stream_in)) = '1' then
                        current_output <= selected_output;
                        state          <= Active when stream_in(selected_output).tlast = '0' else
                            Idle;
                    end if;
                when Active =>
                    if stream_in(current_output).tvalid = '1' and stream_in(current_output).tlast = '1' and stream_in_ready(current_output) = '1' then
                        state <= Idle;
                    end if;
            end case;

            if reset = '1' then
                state          <= Idle;
                current_output <= 0;
            end if;
        end if;
    end process;
end architecture;