library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;
    use work.axis_packet_pkg.all;

entity axis_packet_fifo_sync_dut is
    generic (
        g_depth              : POSITIVE  := 16;
        g_almost_full_ena    : BOOLEAN   := false;
        g_almost_full_level  : natural   := 0;
        g_almost_empty_ena   : BOOLEAN   := false;
        g_almost_empty_level : natural   := 0;
        g_ram_style          : string    := "auto";
        g_ram_behavior       : string    := "RBW";
        g_ready_reset_state  : STD_LOGIC := '1'
    );
    port (
        -- Input interface
        clk              : in  std_logic;
        reset            : in  std_logic;

        packet_in        : in  t_axis_packet_32;
        packet_in_meta   : in  std_logic_vector(31 downto 0);
        packet_in_ready  : out std_logic;

        packet_out       : out t_axis_packet_32;
        packet_out_meta  : out std_logic_vector(31 downto 0);
        packet_out_ready : in  std_logic;

        -- Output Status
        packet_in_level  : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        packet_out_level : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        full             : out std_logic;
        empty            : out std_logic;
        almost_full      : out std_logic;
        almost_empty     : out std_logic
    );
end entity;

architecture structure of axis_packet_fifo_sync_dut is
begin
    i_dut: entity work.axis_packet_fifo_sync
        generic map (
            g_depth              => g_depth,
            g_almost_full_ena    => g_almost_full_ena,
            g_almost_full_level  => g_almost_full_level,
            g_almost_empty_ena   => g_almost_empty_ena,
            g_almost_empty_level => g_almost_empty_level,
            g_ram_style          => g_ram_style,
            g_ram_behavior       => g_ram_behavior,
            g_ready_reset_state  => g_ready_reset_state
        )
        port map (
            clk              => clk,
            reset            => reset,
            packet_in        => packet_in,
            packet_in_meta   => packet_in_meta,
            packet_in_ready  => packet_in_ready,
            packet_out       => packet_out,
            packet_out_meta  => packet_out_meta,
            packet_out_ready => packet_out_ready,
            packet_in_level  => packet_in_level,
            packet_out_level => packet_out_level,
            full             => full,
            empty            => empty,
            almost_full      => almost_full,
            almost_empty     => almost_empty
        );
end architecture;
