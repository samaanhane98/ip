library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;

entity fifo_sync is
    generic (
		g_storage: string := "auto";
		g_output_reg : natural range 0 to 16 := 0;
		g_data_width: integer := 32;
        g_depth : integer := 16
    );
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
		
        write_data     : in std_logic_vector(g_data_width - 1 downto 0);
        write_valid    : in std_logic;
        write_ready    : out  std_logic := '1';
        write_level    : out std_logic_vector(integer(log2(g_depth)) - 1 downto 0);

        read_data      : out  std_logic_vector(g_data_width - 1 downto 0);
        read_valid     : out  std_logic;
        read_ready     : in std_logic;
        read_level     : out std_logic_vector(integer(log2(g_depth)) - 1 downto 0);

        -- Status
        full         : out std_logic;
        almost_full  : out std_logic;
        empty        : out std_logic;
        almost_empty : out std_logic
    );
end entity;

architecture behavior of fifo_sync is
	signal read_pointer  : std_logic_vector(integer(log2((g_depth))) - 1 downto 0);
	signal write_pointer : std_logic_vector(integer(log2((g_depth))) - 1 downto 0);

	signal write_ena: std_logic;
begin
	write_ready <= not full;
	read_valid <= not empty;

	write_level <= write_pointer;
	read_level <= read_pointer;

	p_full_gen: process (write_pointer, read_pointer)
    begin
        full <= '0';
		almost_full <= '0';
        if unsigned(write_pointer) + 1 = unsigned(read_pointer) then
            full <= '1';
        end if;

        if unsigned(write_pointer) + 2 = unsigned(read_pointer) then
            almost_full <= '1';
        end if;

    end process;

	p_empty_gen: process (write_pointer, read_pointer)
    begin
        empty <= '0';
		almost_empty <= '0';
        if read_pointer = write_pointer then
            empty <= '1';
        end if;

        if unsigned(read_pointer) + 1 = unsigned(write_pointer) then
            almost_empty <= '1';
        end if;
    end process;


	p_write: process (clk)
	begin
		if rising_edge(clk) then
			if write_valid = '1' and write_ready = '1' and full = '0' then
				write_pointer <= std_logic_vector(unsigned(write_pointer) + 1);
			end if;
			
			if reset = '1' then
				write_pointer <= (others => '0');
			end if;
		end if;
	end process;

	p_read: process (clk)
	begin
		if rising_edge(clk) then
			if read_valid = '1' and read_ready = '1' and empty = '0' then
				read_pointer <= std_logic_vector(unsigned(read_pointer) + 1);
			end if;
			
			if reset = '1' then
				read_pointer <= (others => '0');
			end if;
		end if;
	end process;


	write_ena <= write_valid and write_ready;

	i_ram_sdp: entity work.ram_sdp
	 	generic map (
			g_storage => g_storage,	
			g_output_reg => g_output_reg,
			g_ram_width => g_data_width,
			g_ram_depth => g_depth
		)
		port map (
			clk           => clk,
			reset         => reset,
			read_address  => read_pointer,
			read_ena      => '1',
			read_data     => read_data,
			write_address => write_pointer,
			write_ena     => write_ena,
			write_data    => write_data
		);
end architecture;
