library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package vec_pkg is
    type t_vec_array is array(natural range<>) of std_logic_vector;    
    
    subtype t_vec_array_8 is t_vec_array(open)(7 downto 0);
    subtype t_vec_array_32 is t_vec_array(open)(31 downto 0);
end package vec_pkg;