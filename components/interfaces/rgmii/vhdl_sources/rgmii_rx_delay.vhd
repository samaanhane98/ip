library ieee;
    use ieee.std_logic_1164.all;

library unisim;
    use unisim.vcomponents.all;

entity rgmii_rx_delay is
    generic (
        g_idelay_value     : positive := 20;
        g_refclk_frequency : real     := 200.0;
        g_iodelay_group    : string   := "rgmii_idelay_group"
    );
    port (
        idelay_refclk      : in  std_logic;
        idelay_rst         : in  std_logic;
        idelay_rdy         : out std_logic;

        rgmii_rxc          : in  std_logic;
        rgmii_rd           : in  std_logic_vector(3 downto 0);
        rgmii_rx_ctl       : in  std_logic;

        rgmii_rd_delay     : out std_logic_vector(3 downto 0);
        rgmii_rx_ctl_delay : out std_logic
    );
end entity;

architecture structure of rgmii_rx_delay is

begin
    gen_idelayctrl: block
        attribute IODELAY_GROUP                    : string;
        attribute IODELAY_GROUP of IDELAYCTRL_inst : label is g_iodelay_group;
    begin
        IDELAYCTRL_inst: IDELAYCTRL
        port map (
            RDY    => idelay_rdy,
            REFCLK => idelay_refclk,
            RST    => idelay_rst
        );
    end block;

    gen_rd_delay: for i in 0 to 3 generate
        attribute IODELAY_GROUP                  : string;
        attribute IODELAY_GROUP of IDELAYE2_inst : label is g_iodelay_group;
    begin
        IDELAYE2_inst: IDELAYE2
            generic map (
                CINVCTRL_SEL          => "FALSE",
                DELAY_SRC             => "IDATAIN",
                HIGH_PERFORMANCE_MODE => "FALSE",
                IDELAY_TYPE           => "FIXED",
                IDELAY_VALUE          => g_idelay_value,
                PIPE_SEL              => "FALSE",
                REFCLK_FREQUENCY      => g_refclk_frequency,
                SIGNAL_PATTERN        => "DATA"
            )
            port map (
                CNTVALUEOUT => open,
                DATAOUT     => rgmii_rd_delay(i),
                C           => rgmii_rxc,
                CE          => '0',
                CINVCTRL    => '0',
                CNTVALUEIN  => (others => '0'),
                DATAIN      => '0',
                IDATAIN     => rgmii_rd(i),
                INC         => '0',
                LD          => '0',
                LDPIPEEN    => '0',
                REGRST      => '0'
            );
    end generate;

    ctl_delay: block is
        attribute IODELAY_GROUP                       : string;
        attribute IODELAY_GROUP of IDELAYE2_ctrl_inst : label is g_iodelay_group;
    begin
        IDELAYE2_ctrl_inst: IDELAYE2
            generic map (
                CINVCTRL_SEL          => "FALSE",
                DELAY_SRC             => "IDATAIN",
                HIGH_PERFORMANCE_MODE => "FALSE",
                IDELAY_TYPE           => "FIXED",
                IDELAY_VALUE          => g_idelay_value,
                PIPE_SEL              => "FALSE",
                REFCLK_FREQUENCY      => g_refclk_frequency,
                SIGNAL_PATTERN        => "DATA"
            )
            port map (
                CNTVALUEOUT => open,
                DATAOUT     => rgmii_rx_ctl_delay,
                C           => rgmii_rxc,
                CE          => '0',
                CINVCTRL    => '0',
                CNTVALUEIN  => (others => '0'),
                DATAIN      => '0',
                IDATAIN     => rgmii_rx_ctl,
                INC         => '0',
                LD          => '0',
                LDPIPEEN    => '0',
                REGRST      => '0'
            );
    end block;
end architecture;
