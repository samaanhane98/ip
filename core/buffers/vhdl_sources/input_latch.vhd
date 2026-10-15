library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://pavel-demin.github.io/red-pitaya-notes/axi-interface-buffers/
-- Combination of input buffer and output buffer
entity input_latch is
    port (
        clk       : in std_logic;
        reset     : in std_logic;

        in_data   : in std_logic_vector;
        in_valid  : in std_logic;
        in_ready  : out std_logic;

        out_data  : out std_logic_vector;
        out_valid : out std_logic;
        out_ready : in std_logic
    );
end entity;

architecture behavior of input_latch is
    signal ready        : std_logic;
    signal reg_in_valid : std_logic;
    signal reg_in_data  : std_logic_vector(in_data'range);
begin
    ready     <= out_ready or not reg_in_valid;
    in_ready  <= ready;
    
    p_input_reg : process (clk)
    begin
        if rising_edge(clk) then
            if ready = '1' then
                reg_in_data <= in_data;
            end if;

            if ready = '1' then
                reg_in_valid <= in_valid;
            end if;

            if reset = '1' then
                reg_in_valid <= '1';
                reg_in_data  <= (others => '0');
            end if;
        end if;
    end process;

    p_output_mux : process (all)
    begin
        if ready = '1' then
            out_data <= in_data;
            out_valid <= in_valid;
        else
            out_data <= reg_in_data;
            out_valid <= reg_in_valid;
        end if;
    end process;
end architecture;