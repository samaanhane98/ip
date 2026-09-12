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

    subtype t_axis_8 is t_axis(tdata(7 downto 0), tkeep(0 downto 0), tuser(- 1 downto 0));
    subtype t_axis_32 is t_axis(tdata(31 downto 0), tkeep(3 downto 0), tuser(- 1 downto 0));

    subtype t_axis_8_u8 is t_axis(tdata(7 downto 0), tkeep(0 downto 0), tuser(7 downto 0));
    subtype t_axis_32_u8 is t_axis(tdata(31 downto 0), tkeep(3 downto 0), tuser(7 downto 0));

    function pack(axis : t_axis) return std_logic_vector;
    function unpack(vec : std_logic_vector; axis : t_axis) return t_axis;

    function get_size(axis : t_axis) return natural;
end package;

package body axis_pkg is
    function pack(axis : t_axis) return std_logic_vector is
        variable v_result : std_logic_vector(get_size(axis) - 1 downto 0);
    begin
        return axis.tkeep & axis.tuser & axis.tdata & axis.tlast & axis.tvalid;
    end function;

    function unpack(vec : std_logic_vector; axis : t_axis) return t_axis is
        variable v_result : t_axis(tdata(axis.tdata'range), tuser(axis.tuser'range), tkeep(axis.tkeep'range));
        variable v_len    : integer;
        variable v_offset : integer;
    begin
        v_offset := 0;
        v_len := 1;
        v_result.tvalid := vec(v_offset);

        v_offset := v_offset + v_len;
        v_len := 1;
        v_result.tlast := vec(v_offset);

        v_offset := v_offset + v_len;
        v_len := axis.tdata'length;
        v_result.tdata := vec(v_offset + v_len - 1 downto v_offset);

        v_offset := v_offset + v_len;
        v_len := axis.tuser'length;
        v_result.tuser := vec(v_offset + v_len - 1 downto v_offset);

        v_offset := v_offset + v_len;
        v_len := axis.tkeep'length;
        v_result.tkeep := vec(v_offset + v_len - 1 downto v_offset);

        return v_result;
    end function;

    function get_size(axis : t_axis) return natural is
    begin
        return 1 + 1 + axis.tdata'length + axis.tuser'length + axis.tkeep'length;
    end function;
end package body;
