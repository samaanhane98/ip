library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity reset_synchronizer is
	generic (
		g_sync_stages: natural range 2 to 16 := 2
	);
	port (
		reset : in std_logic;
		dst_clk : in std_logic;
		dst_reset : out std_logic
	);
end entity;

architecture behavior of reset_synchronizer is
	attribute ASYNC_REG: string;
	attribute SHREG_EXTRACT: string;

	signal reset_sync: std_logic_vector(g_sync_stages - 1 downto 0);
	attribute ASYNC_REG of reset_sync: signal is "TRUE";
	attribute SHREG_EXTRACT of reset_sync: signal is "FALSE";
begin
	dst_reset <= reset_sync(reset_sync'high);

	-- Asynchronously reset FF, synchronously release
	p_sync_reset: process (dst_clk, reset)
	begin
		if rising_edge(dst_clk) then
			reset_sync <= reset_sync(reset_sync'high - 1 downto 0) & '0';
		end if;

		if reset = '1' then
			reset_sync <= (others => '1');
		end if;
	end process;
end architecture;