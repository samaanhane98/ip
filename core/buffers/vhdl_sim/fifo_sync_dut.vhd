library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;

entity fifo_sync_dut is
    generic (
        g_depth : POSITIVE := 32
    );
    port (
        -- Input interface
        clk          : in  std_logic;
        reset        : in  std_logic;

        wr_data      : in  std_logic_vector(7 downto 0);
        wr_valid     : in  std_logic := '1';
        wr_ready     : out std_logic;

        -- Output Interface
        rd_data      : out std_logic_vector(7 downto 0);
        rd_valid     : out std_logic;
        rd_ready     : in  std_logic := '1';

        -- Output Status
        wr_level     : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        rd_level     : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        full         : out std_logic;
        empty        : out std_logic;
        almost_full  : out std_logic;
        almost_empty : out std_logic

    );
end entity;

architecture structure of fifo_sync_dut is
begin
    i_dut: entity work.fifo_sync
        generic map (
            g_depth => g_depth
        )
        port map (
            clk          => clk,
            reset        => reset,
            wr_data      => wr_data,
            wr_valid     => wr_valid,
            wr_ready     => wr_ready,
            rd_data      => rd_data,
            rd_valid     => rd_valid,
            rd_ready     => rd_ready,
            wr_level     => wr_level,
            rd_level     => rd_level,
            full         => full,
            empty        => empty,
            almost_full  => almost_full,
            almost_empty => almost_empty
        );
end architecture;
