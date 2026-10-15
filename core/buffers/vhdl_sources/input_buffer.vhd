library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- https://pavel-demin.github.io/red-pitaya-notes/axi-interface-buffers/
-- Input buffer
entity input_buffer is
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

architecture behavior of input_buffer is
    signal valid        : std_logic;
    signal reg_in_ready : std_logic;
    signal reg_in_data  : std_logic_vector(in_data'range);
begin
    valid <= in_valid or not reg_in_ready;
    out_valid <= valid;
    in_ready <= reg_in_ready;

    p_input_reg : process (clk)
    begin
        if rising_edge(clk) then
            if reg_in_ready = '1' then
                reg_in_data <= in_data;
            end if;

            if valid = '1' then
                reg_in_ready <= out_ready;
            end if;

            if reset = '1' then
                reg_in_ready <= '1';
                reg_in_data  <= (others => '0');
            end if;
        end if;
    end process;

    p_output_mux : process (all)
    begin
        if reg_in_ready = '1' then
            out_data <= in_data;
        else
            out_data <= reg_in_data;
        end if;
    end process;
end architecture;