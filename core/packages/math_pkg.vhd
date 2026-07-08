library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package math_pkg is
    function log2(depth : in natural) return integer;
end package;

package body math_pkg is

    function log2(depth : natural) return integer is
        variable v_temp   : integer := depth;
        variable v_return : integer := 0;
    begin
        while v_temp > 1 loop
            v_return := v_return + 1;
            v_temp := v_temp / 2;
        end loop;
        return v_return;
    end function;
end package body;
