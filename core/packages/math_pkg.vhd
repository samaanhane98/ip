library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package math_pkg is
    function log2(depth : in natural) return natural;
    function log2ceil(depth : in natural) return natural;
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

  function log2ceil (arg : in natural) return natural is
    begin
        if arg = 0 then
            return 0;
        end if;
        return log2(arg * 2 - 1);
    end function;
end package body;
