library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity input_synchronizer is
    generic (
        g_sync_stages : INTEGER range 2 to 16 := 2;
        g_reset_val   : STD_LOGIC             := '0'
    );
    port (
        input    : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        dest_clk : in  STD_LOGIC;
        output   : out STD_LOGIC
    );
end entity;

architecture behavior of input_synchronizer is
    signal output_sr : STD_LOGIC_VECTOR(g_sync_stages - 1 downto 0);

    attribute ASYNC_REG              : STRING;
    attribute ASYNC_REG of output_sr : signal is "TRUE";

    signal input_reg : STD_LOGIC;

    attribute IOB              : STRING;
    attribute IOB of input_reg : signal is "TRUE";
begin
    output <= output_sr(output_sr'high);

    p_reg: process (dest_clk)
    begin
        if rising_edge(dest_clk) then
            input_reg <= input;
            output_sr <= output_sr(output_sr'high - 1 downto 0) & input_reg;

            if reset = '1' then
                input_reg <= '0';
                output_sr <= (others => g_reset_val);
            end if;
        end if;
    end process;
end architecture;
