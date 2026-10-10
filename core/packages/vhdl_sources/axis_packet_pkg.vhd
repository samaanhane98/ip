library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axis_packet_pkg is
    type t_axis_packet is record
        valid      : std_logic;
        last       : std_logic;
        first      : std_logic;
        drop       : std_logic;
        data       : std_logic_vector;
        user       : std_logic_vector;
        keep       : std_logic_vector;
        meta_valid : std_logic;
    end record;

    subtype t_axis_packet_32 is t_axis_packet(data(31 downto 0), keep(3 downto 0), user(-1 downto 0));
    subtype t_axis_packet_32_u8 is t_axis_packet(data(31 downto 0), keep(3 downto 0), user(7 downto 0));

    function pack(axis_packet     : t_axis_packet) return std_logic_vector;
    function unpack(vec : std_logic_vector; axis_packet : t_axis_packet) return t_axis_packet;

    function get_size(axis_packet : t_axis_packet) return natural;

    type t_axis_packet_array is array(natural range <>) of t_axis_packet;

    subtype t_axis_packet_32_array is t_axis_packet_array(open)(data(31 downto 0), keep(3 downto 0), user(-1 downto 0));
    subtype t_axis_packet_32_u8_array is t_axis_packet_array(open)(data(31 downto 0), keep(3 downto 0), user(7 downto 0));
end package;

package body axis_packet_pkg is
    function pack(axis_packet : t_axis_packet) return std_logic_vector is
        variable v_result         : std_logic_vector(get_size(axis_packet) - 1 downto 0);
    begin
        return axis_packet.meta_valid & axis_packet.keep & axis_packet.user & axis_packet.data & axis_packet.drop & axis_packet.first & axis_packet.last & axis_packet.valid;
    end function;

    function unpack(vec : std_logic_vector; axis_packet : t_axis_packet) return t_axis_packet is
        variable v_result : t_axis_packet(data(axis_packet.data'range), user(axis_packet.user'range), keep(axis_packet.keep'range));
        variable v_len    : integer;
        variable v_offset : integer;
    begin
        v_offset            := 0;
        v_len               := 1;
        v_result.valid      := vec(v_offset);

        v_offset            := v_offset + v_len;
        v_len               := 1;
        v_result.last       := vec(v_offset);

        v_offset            := v_offset + v_len;
        v_len               := 1;
        v_result.first      := vec(v_offset);

        v_offset            := v_offset + v_len;
        v_len               := 1;
        v_result.drop       := vec(v_offset);

        v_offset            := v_offset + v_len;
        v_len               := axis_packet.data'length;
        v_result.data       := vec(v_offset + v_len - 1 downto v_offset);

        v_offset            := v_offset + v_len;
        v_len               := axis_packet.user'length;
        v_result.user       := vec(v_offset + v_len - 1 downto v_offset);

        v_offset            := v_offset + v_len;
        v_len               := axis_packet.keep'length;
        v_result.keep       := vec(v_offset + v_len - 1 downto v_offset);

        v_offset            := v_offset + v_len;
        v_len               := 1;
        v_result.meta_valid := vec(v_offset);

        return v_result;
    end function;

    function get_size(axis_packet : t_axis_packet) return natural is
    begin
        return 1 + 1 + 1 + 1 + axis_packet.data'length + axis_packet.user'length + axis_packet.keep'length + 1;
    end function;
end package body;