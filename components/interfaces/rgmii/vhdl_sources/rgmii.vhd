library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity rgmii is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;

        ref_clk    : in  std_logic;

        rxc        : in  std_logic;
        rx_ctl     : in  std_logic;
        rd         : in  std_logic_vector(3 downto 0);

        data_out   : out std_logic_vector(7 downto 0);
        data_valid : out std_logic;
        data_error : out std_logic
    );
end entity;

architecture behavior of rgmii is
    signal ref_reset    : std_logic;
    signal rx_ctl_delay : std_logic;
    signal rd_delay     : std_logic_vector(3 downto 0);

begin
    i_reset_synchronizer: entity work.reset_synchronizer
        port map (
            reset     => reset,
            dst_clk   => ref_clk,
            dst_reset => ref_reset
        );

    rgmii_rx_delay_inst: entity work.rgmii_rx_delay
        generic map (
            g_idelay_value     => 20,
            g_refclk_frequency => 200.0,
            g_iodelay_group    => "rgmii_idelay_group"
        )
        port map (
            idelay_refclk      => ref_clk,
            idelay_rst         => ref_reset,
            idelay_rdy         => open,
            rgmii_rxc          => rxc,
            rgmii_rd           => rd,
            rgmii_rx_ctl       => rx_ctl,
            rgmii_rd_delay     => rd_delay,
            rgmii_rx_ctl_delay => rx_ctl_delay
        );

    i_rgmii_to_data: entity work.rgmii_to_data
        port map (
            clk        => clk,
            reset      => reset,
            rxc        => rxc,
            rx_ctl     => rx_ctl_delay,
            rd         => rd_delay,
            data_out   => data_out,
            data_valid => data_valid,
            data_error => data_error
        );
end architecture;
