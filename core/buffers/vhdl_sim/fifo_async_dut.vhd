library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;

entity fifo_async_dut is
    generic (
        g_depth : POSITIVE := 32
    );
    port (
        -- Input interface
        wr_clk          : in  std_logic;
        wr_reset        : in  std_logic;

        wr_data         : in  std_logic_vector(7 downto 0);
        wr_valid        : in  std_logic := '1';
        wr_ready        : out std_logic;

        -- Input Status
        wr_full         : out std_logic;
        wr_empty        : out std_logic;
        wr_almost_full  : out std_logic;
        wr_almost_empty : out std_logic;

        -- Output Interface
        rd_clk          : in  std_logic;
        rd_reset        : in  std_logic;
        rd_data         : out std_logic_vector(7 downto 0);
        rd_valid        : out std_logic;
        rd_ready        : in  std_logic := '1';

        -- Output Status
        rd_full         : out std_logic;
        rd_empty        : out std_logic;
        rd_almost_full  : out std_logic;
        rd_almost_empty : out std_logic;
        wr_level        : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);
        rd_level        : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0)

    );
end entity;

architecture structure of fifo_async_dut is
begin
    i_dut: entity work.fifo_async
        generic map (
            g_depth => g_depth
        )
        port map (
            wr_clk          => wr_clk,
            wr_reset        => wr_reset,
            wr_data         => wr_data,
            wr_valid        => wr_valid,
            wr_ready        => wr_ready,
            wr_full         => wr_full,
            wr_empty        => wr_empty,
            wr_almost_full  => wr_almost_full,
            wr_almost_empty => wr_almost_empty,
            wr_level        => wr_level,
            rd_clk          => rd_clk,
            rd_reset        => rd_reset,
            rd_data         => rd_data,
            rd_valid        => rd_valid,
            rd_ready        => rd_ready,
            rd_full         => rd_full,
            rd_empty        => rd_empty,
            rd_almost_full  => rd_almost_full,
            rd_almost_empty => rd_almost_empty,
            rd_level        => rd_level
        );
end architecture;
