library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity rgmii_rx is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;

        idelay_ref_clk   : in  std_logic;
        idelay_ref_reset : in  std_logic;

        rxc              : in  std_logic;
        rx_ctl           : in  std_logic;
        rd               : in  std_logic_vector(3 downto 0);

        data_out         : out std_logic_vector(7 downto 0);
        data_valid       : out std_logic;
        data_error       : out std_logic
    );
end entity;

architecture behavior of rgmii_rx is
    signal rx_ctl_deskew : std_logic;
    signal rd_deskew     : std_logic_vector(3 downto 0);

begin
    i_rgmii_rx_deskew: entity work.rgmii_rx_deskew
        generic map (
            g_idelay_value     => 20,
            g_refclk_frequency => 200.0,
            g_iodelay_group    => "rgmii_idelay_group"
        )
        port map (
            idelay_ref_clk      => idelay_ref_clk,
            idelay_ref_reset    => idelay_ref_reset,
            rgmii_rxc           => rxc,
            rgmii_rd            => rd,
            rgmii_rx_ctl        => rx_ctl,
            rgmii_rd_deskew     => rd_deskew,
            rgmii_rx_ctl_deskew => rx_ctl_deskew
        );

    i_rgmii_to_data: entity work.rgmii_to_data
        port map (
            clk        => clk,
            reset      => reset,
            rxc        => rxc,
            rx_ctl     => rx_ctl_deskew,
            rd         => rd_deskew,
            data_out   => data_out,
            data_valid => data_valid,
            data_error => data_error
        );
end architecture;
