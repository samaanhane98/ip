library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;
    use work.axis_pkg.all;

entity axis_fifo_sync_dut is
    generic (
        g_depth : positive := 16
    );
    port (
        -- Input interface
        clk              : in  std_logic;
        reset            : in  std_logic;

        stream_in        : in  t_axis_32;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis_32;
        stream_out_ready : in  std_logic;

        -- Output Status
        stream_in_level  : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        stream_out_level : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        full             : out std_logic;
        empty            : out std_logic
    );
end entity;

architecture structure of axis_fifo_sync_dut is

begin
    i_dut: entity work.axis_fifo_sync
        generic map (
            g_depth => g_depth
        )
        port map (
            clk              => clk,
            reset            => reset,
            stream_in        => stream_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => stream_out,
            stream_out_ready => stream_out_ready,
            stream_in_level  => stream_in_level,
            stream_out_level => stream_out_level,
            full             => full,
            empty            => empty,
            almost_full      => open,
            almost_empty     => open
        );
end architecture;
