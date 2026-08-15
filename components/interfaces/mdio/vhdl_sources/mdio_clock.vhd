library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity mdio_clock is
    generic (
        g_mdc_half_period : integer := 32
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;

        mdc        : out std_logic;
        mdc_fe     : out std_logic;
        mdc_sample : out std_logic;
        mdc_count  : out unsigned(7 downto 0)

    );
end entity;

architecture behavior of mdio_clock is
    constant g_mdc_full_period : integer := g_mdc_half_period * 2;
	constant g_mdio_sample_period: integer := g_mdc_half_period + g_mdc_half_period / 2;

    signal count : integer;
    signal mdc_d1 : std_logic;
begin
    mdc       <= '1' when count < g_mdc_half_period and reset /= '1' else '0';
    mdc_count <= to_unsigned(count, 8);

	mdc_d1 <= mdc when rising_edge(clk);
	mdc_fe <= (not mdc) and mdc_d1;
	mdc_sample <= '1' when count = g_mdio_sample_period else '0';

    p_count: process (clk)
    begin
        if rising_edge(clk) then
            if count = g_mdc_full_period - 1 then
                count <= 0;
            else
                count <= count + 1;
            end if;

            if reset = '1' then
                count <= 0;
            end if;
        end if;
    end process;
end architecture;
