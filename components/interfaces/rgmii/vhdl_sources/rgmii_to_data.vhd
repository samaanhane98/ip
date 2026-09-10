library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library unisim;
    use unisim.vcomponents.all;

entity rgmii_to_data is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;

        rxc        : in  std_logic;
        rx_ctl     : in  std_logic;
        rd         : in  std_logic_vector(3 downto 0);

        data_out   : out std_logic_vector(7 downto 0);
        data_valid : out std_logic;
        data_error : out std_logic
    );
end entity;

architecture structure of rgmii_to_data is
    signal reset_rxc : std_logic;
    signal data_re   : std_logic_vector(3 downto 0);
    signal data_fe   : std_logic_vector(3 downto 0);

    signal rx_dv     : std_logic;
    signal rx_ctl_fe : std_logic;
    signal rx_err    : std_logic;
begin

    i_reset_synchronizer: entity work.reset_synchronizer
        port map (
            reset     => reset,
            dst_clk   => rxc,
            dst_reset => reset_rxc
        );

    gen_rx_data_iddr: for i in 0 to 3 generate
        IDDR_inst: IDDR
            generic map (
                DDR_CLK_EDGE => "SAME_EDGE_PIPELINED"
            )
            port map (
                Q1 => data_re(i),
                Q2 => data_fe(i),
                C  => rxc,
                CE => '1',
                D  => rd(i),
                R  => reset_rxc,
                S  => '0'
            );

    end generate;

    IDDR_ctl_inst: IDDR
        generic map (
            DDR_CLK_EDGE => "SAME_EDGE_PIPELINED"
        )
        port map (
            Q1 => rx_dv,
            Q2 => rx_ctl_fe,
            C  => rxc,
            CE => '1',
            D  => rx_ctl,
            R  => reset_rxc,
            S  => '0'
        );

    rx_err <= rx_dv xor rx_ctl_fe;

    i_cdc_fifo: entity work.fifo_async
        generic map (
            g_width        => 10,
            g_depth        => 2,
            g_optimization => "SPEED"
        )
        port map (
            wr_clk              => rxc,
            wr_reset            => reset,

            wr_data             => rx_err & rx_dv & data_fe & data_re,
            wr_valid            => '1',
            wr_ready            => open,

            -- Input Status
            wr_full             => open,
            wr_empty            => open,
            wr_almost_full      => open,
            wr_almost_empty     => open,
            wr_level            => open,

            -- Output Interface
            rd_clk              => clk,
            rd_reset            => reset,
            rd_data(7 downto 0) => data_out,
            rd_data(8)          => data_valid,
            rd_data(9)          => data_error,
            rd_valid            => open,
            rd_ready            => '1',

            -- Output Status
            rd_full             => open,
            rd_empty            => open,
            rd_almost_full      => open,
            rd_almost_empty     => open,
            rd_level            => open
        );
end architecture;
