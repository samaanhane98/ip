library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity input_latch_dut is
    port (
        -- Input interface
        clk       : in std_logic;
        reset     : in std_logic;

        in_data   : in std_logic_vector(7 downto 0);
        in_valid  : in std_logic;
        in_ready  : out std_logic;

        -- Output Interface
        out_data  : out std_logic_vector(7 downto 0);
        out_valid : out std_logic;
        out_ready : in std_logic 
    );
end entity;

architecture structure of input_latch_dut is
begin
    i_dut : entity work.input_latch
        port map(
            clk       => clk,
            reset     => reset,
            in_data   => in_data,
            in_valid  => in_valid,
            in_ready  => in_ready,
            out_data  => out_data,
            out_valid => out_valid,
            out_ready => out_ready
        );
end architecture;