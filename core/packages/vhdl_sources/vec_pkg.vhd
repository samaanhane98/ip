library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package vec_pkg is
    type t_vec_array is array(natural range<>) of std_logic_vector;    
    
    subtype t_vec_array_8 is t_vec_array(open)(7 downto 0);
    subtype t_vec_array_32 is t_vec_array(open)(31 downto 0);

    type t_unsigned_array is array(natural range<>) of unsigned;

    --function slice(vec: std_logic_vector; high: natural; low: natural) return std_logic_vector;
end package vec_pkg;

package body vec_pkg is
    
    --function slice(vec: std_logic_vector; high: natural; low: natural) return std_logic_vector is
    --begin
    --    assert not vec'ascending report "Vector range not downto" severity failure;

    --    return vec(high downto)
    --end function;
    
    
end package body vec_pkg;