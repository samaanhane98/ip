library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity mdio_tb is
end entity;

architecture tb of mdio_tb is
    constant c_clk_period : time := 8 ns;

    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';
    signal op       : std_logic;
    signal phy_addr : std_logic_vector(4 downto 0);
    signal reg_addr : std_logic_vector(4 downto 0);
    signal data : std_logic_vector(15 downto 0);

    signal ena      : std_logic;
    signal busy     : std_logic;
    signal valid    : std_logic;
    signal resp     : std_logic_vector(15 downto 0);
    signal mdc      : std_logic;
    signal mdio_io  : std_logic;
begin
	clk <= not clk after c_clk_period / 2;
	reset <= '0' after 10 * c_clk_period;

	process
	begin
		wait until reset = '0';
		op <= '1';
		phy_addr <= (others => '0');
		reg_addr <= std_logic_vector(to_unsigned(4, 5));
		data <= std_logic_vector(to_unsigned(4, 16));

		ena <= '1';

		wait until busy = '1';
		ena <= '0';

		wait;
	end process;

    i_mdio: entity work.mdio
        generic map (
            g_mdc_half_period => 32
        )
        port map (
            clk      => clk,
            reset    => reset,
            op       => op,
            phy_addr => phy_addr,
            reg_addr => reg_addr,
            data     => data,
            ena      => ena,
            busy     => busy,
            valid    => valid,
            resp     => resp,
            mdc      => mdc,
            mdio_io  => mdio_io
        );

	p_mdio_slave: process (mdc)
		variable v_bit_count: integer := 0;
	begin
		if rising_edge(mdc) then
			if reset /= '1' and busy = '1' then
				-- Print the current bit number and the value of mdio_io
				report "Bit number: " & integer'image(v_bit_count) & 
					", MDIO_IO value: " & std_logic'image(mdio_io) 
				severity note;

				-- Increment bit counter for the next clock cycle
				v_bit_count := v_bit_count + 1;
			end if;
		end if;
	end process;
end architecture;
