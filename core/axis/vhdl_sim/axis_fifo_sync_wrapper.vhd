library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.axis_pkg.all;

entity axis_fifo_sync_wrapper is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        stream_in        : in  t_axis_32;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis_32;
        stream_out_ready : in  std_logic
    );
end entity;

architecture structure of axis_fifo_sync_wrapper is
begin
    axis_fifo_sync_inst: entity work.axis_fifo_sync
        generic map (
            g_implementation => "auto",
            g_word_depth     => 12
        )
        port map (
            clk              => clk,
            reset            => reset,
            stream_in        => stream_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => stream_out,
            stream_out_ready => stream_out_ready
        );
end architecture;
