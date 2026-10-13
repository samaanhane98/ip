library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package math_pkg is
    function log2(depth : in natural) return natural;
    function log2ceil(arg : in natural) return natural;

    function or_reduce(arg: in std_logic_vector) return std_logic;
    function and_reduce(arg: in std_logic_vector) return std_logic;
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

    function or_reduce(arg: in std_logic_vector) return std_logic is
        variable v_result: std_logic;
    begin
        v_result := '0';
        for index in arg'range loop
            v_result := v_result or arg(index);
        end loop;
        return v_result;
    end function;

    function and_reduce(arg: in std_logic_vector) return std_logic is
        variable v_result: std_logic;
    begin
        v_result := '0';
        for index in arg'range loop
            v_result := v_result and arg(index);
        end loop;
        return v_result;
    end function;
end package body;
