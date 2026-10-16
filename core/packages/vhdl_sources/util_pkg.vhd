library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package util_pkg is
    function keep_to_bytes(vec: std_logic_vector) return natural;
    
    
end package util_pkg;

package body util_pkg is
    
    function keep_to_bytes(vec: std_logic_vector) return natural is
        alias norm_vec : std_logic_vector(vec'length - 1 downto 0) is vec;
        variable v_result: natural;
    begin
        v_result := 0;
        for i in norm_vec'reverse_range loop
            if norm_vec(i) = '1' then
                v_result := v_result + 1;
            end if;
        end loop;
        return v_result;
    end function;
end package body util_pkg;