library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;
    use work.axis_pkg.all;

entity axis_fifo_sync is
    generic (
        g_depth              : POSITIVE  := 32;
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

        stream_in        : in  t_axis;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis;
        stream_out_ready : in  std_logic;

        -- Output Status
        wr_level         : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        rd_level         : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        full             : out std_logic;
        empty            : out std_logic;
        almost_full      : out std_logic;
        almost_empty     : out std_logic
    );
end entity;

architecture structure of axis_fifo_sync is
    signal stream_in_slv  : std_logic_vector(get_size(stream_in) - 1 downto 0);
    signal stream_out_slv : std_logic_vector(get_size(stream_out) - 1 downto 0);

    signal rd_valid : std_logic;
begin
    stream_in_slv <= pack(stream_in);

    i_fifo_sync: entity work.fifo_sync
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
            clk          => clk,
            reset        => reset,

            wr_data      => stream_in_slv,
            wr_valid     => stream_in.tvalid,
            wr_ready     => stream_in_ready,

            rd_data      => stream_out_slv,
            rd_valid     => rd_valid,
            rd_ready     => stream_out_ready,

            wr_level     => wr_level,
            rd_level     => rd_level,
            full         => full,
            empty        => empty,
            almost_full  => almost_full,
            almost_empty => almost_empty
        );

    stream_out        <= unpack(stream_out_slv, stream_out);
    stream_out.tvalid <= rd_valid;
end architecture;
