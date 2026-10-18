library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity elastic_buffer_dut is
    port (
        wr_data  : in std_logic_vector(7 downto 0);
        wr_valid : in std_logic;
        wr_ready : out std_logic;

        -- Output Interface
        rd_data  : out std_logic_vector(7 downto 0);
        rd_valid : out std_logic;
        rd_ready : in std_logic
    );
end entity;

architecture structure of elastic_buffer_dut is
    signal rd_clk   : std_logic;
    signal rd_reset : std_logic;
    signal wr_clk   : std_logic;
    signal wr_reset : std_logic;
begin
    i_clock_and_reset_bfm : entity work.clock_and_reset_bfm
        generic map(
            g_periods => (0 => 9.999, 1 => 10.001),
            g_resets => (0 => 100, 1 => 100)
        )
        port map(
            clock_out(0) => wr_clk,
            clock_out(1) => rd_clk,
            reset_out(0) => wr_reset,
            reset_out(1) => rd_reset
        );

    wr_ready <= '1';

    elastic_buffer_inst : entity work.elastic_buffer
        port map(
            wr_clk   => wr_clk,
            wr_reset => wr_reset,
            wr_data  => wr_data,
            wr_valid => wr_valid,
            rd_clk   => rd_clk,
            rd_reset => rd_reset,
            rd_data  => rd_data,
            rd_valid => rd_valid
        );
end architecture;