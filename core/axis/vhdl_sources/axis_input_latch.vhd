library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axis_pkg.all;

entity axis_input_latch is
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        stream_in        : in t_axis;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis;
        stream_out_ready : in std_logic
    );
end entity;

architecture structure of axis_input_latch is
    signal stream_in_slv  : std_logic_vector(get_size(stream_in) - 1 downto 0);
    signal stream_out_slv : std_logic_vector(get_size(stream_out) - 1 downto 0);

    signal valid          : std_logic;
begin
    stream_in_slv <= pack(stream_in);

    i_input_latch : entity work.input_latch
        port map(
            clk       => clk,
            reset     => reset,
            in_data   => stream_in_slv,
            in_valid  => stream_in.tvalid,
            in_ready  => stream_in_ready,
            out_data  => stream_out_slv,
            out_valid => valid,
            out_ready => stream_out_ready
        );

    p_assign_output : process (all)
    begin
        stream_out        <= unpack(stream_out_slv, stream_out);
        stream_out.tvalid <= valid;
    end process;
end architecture;