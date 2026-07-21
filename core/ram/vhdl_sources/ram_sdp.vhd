library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;

entity ram_sdp is
    generic (
        g_storage    : string                := "auto"; -- auto, distributed, block
        g_output_reg : natural range 0 to 16 := 2;
        g_ram_width  : integer               := 32;
        g_ram_depth  : integer               := 16
    );
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        read_address  : in  std_logic_vector(log2((g_ram_depth) - 1) downto 0);
        read_ena      : in  std_logic;
        read_data     : out std_logic_vector(g_ram_width - 1 downto 0);
		read_valid	  : out std_logic;
        write_address : in  std_logic_vector(log2((g_ram_depth) - 1) downto 0);
        write_ena     : in  std_logic;
        write_data    : in  std_logic_vector(g_ram_width - 1 downto 0)
    );

end entity;

architecture behavior of ram_sdp is
    subtype t_data is std_logic_vector(g_ram_width - 1 downto 0);
    type t_ram_type is array (g_ram_depth - 1 downto 0) of t_data;
    signal ram : t_ram_type := (others => (others => '0'));

    signal ram_data  : t_data := (others => '0');

    attribute ram_style        : string;
    attribute ram_style of ram : signal is g_storage;
begin

    gen_auto: if g_storage = "auto" or g_storage = "distributed" generate
        p_write_distributed: process (clk)
        begin
            if rising_edge(clk) then
                if (write_ena = '1') then
                    ram(to_integer(unsigned(write_address))) <= write_data;
                end if;
            end if;
        end process;

        ram_data  <= ram(to_integer(unsigned(read_address)));
    end generate;

    gen_block: if g_storage = "block" generate
        p_write_block: process (clk)
        begin
            if rising_edge(clk) then
                if (write_ena = '1') then
                    ram(to_integer(unsigned(write_address))) <= write_data;
                end if;

                if (read_ena = '1') then
                    ram_data <= ram(to_integer(unsigned(read_address)));
                end if;
            end if;
        end process;
    end generate;

    b_output_reg: block
        type t_output_reg_type is array (g_output_reg downto 0) of t_data;
        signal ram_data_reg : t_output_reg_type := (others => (others => '0'));
		signal ram_data_valid: std_logic_vector(g_output_reg downto 0);
    begin
        g_bypass: if g_output_reg = 0 generate
            read_data  <= ram_data;
			read_valid <= '1';
        end generate;

        g_registered: if g_output_reg /= 0 generate
            p_output_reg: process (clk)
            begin
                if rising_edge(clk) then
                    ram_data_reg(g_output_reg) <= ram_data;
					ram_data_valid(g_output_reg) <= read_ena;

                    for i in g_output_reg - 1 downto 0 loop
                        ram_data_reg(i) <= ram_data_reg(i + 1);
                        ram_data_valid(i) <= ram_data_valid(i + 1);
                    end loop;

                    if reset = '1' then
                        ram_data_reg <= (others => (others => '0'));
                        ram_data_valid <= (others => '0');
                    end if;
                end if;
            end process;

            read_data  <= ram_data_reg(0);
			read_valid <= ram_data_valid(0);
        end generate;
    end block;
end architecture;

