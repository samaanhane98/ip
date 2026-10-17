library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity rgmii_rx is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;

        rxc              : in  std_logic;
        rx_ctl           : in  std_logic;
        rd               : in  std_logic_vector(3 downto 0);

        data_out         : out std_logic_vector(7 downto 0);
        data_valid       : out std_logic;
        data_error       : out std_logic
    );
end entity;

architecture behavior of rgmii_rx is
begin
    i_rgmii_to_data: entity work.rgmii_to_data
        port map (
            clk        => clk,
            reset      => reset,
            rxc        => rxc,
            rx_ctl     => rx_ctl,
            rd         => rd,
            data_out   => data_out,
            data_valid => data_valid,
            data_error => data_error
        );
end architecture;
