library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package axis_pkg is
    type t_axis is record
        tvalid : STD_LOGIC;
        tlast  : STD_LOGIC;
        tdata  : STD_LOGIC_VECTOR;
        tuser  : STD_LOGIC_VECTOR;
        tkeep  : STD_LOGIC_VECTOR;
    end record;

    subtype t_axis_32 is t_axis(tdata(31 downto 0), tkeep(3 downto 0), tuser(- 1 downto 0));
    subtype t_axis_32_u8 is t_axis(tdata(31 downto 0), tkeep(3 downto 0), tuser(7 downto 0));
end package;

package body axis_pkg is
end package body;
