library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.math_pkg.all;

entity ram_sdp is
    generic (
        g_width       : natural := 32;
        g_depth       : natural := 1024;
        g_performance : string  := "HIGH_PERFORMANCE";
        g_ram_style   : string  := "auto"; -- auto, block, distributed
        g_init_file   : string  := ""
    );
    port (
        clk      : in std_logic;
        reset    : in std_logic;

        -- Port A: write
        wr_addr  : in std_logic_vector(log2ceil(g_depth) - 1 downto 0);
        wr_data  : in std_logic_vector(g_width - 1 downto 0);
        wr_ena   : in std_logic;
        wr_be    : in std_logic_vector(((g_width + 7) / 8) - 1 downto 0) := (others => '1');

        -- Port B: read
        rd_addr  : in std_logic_vector(log2ceil(g_depth) - 1 downto 0);
        rd_ena   : in std_logic;
        rd_regce : in std_logic := '1';
        rd_data  : out std_logic_vector(g_width - 1 downto 0)
    );
end entity ram_sdp;

architecture behavior of ram_sdp is
    constant c_width_bytes : natural := (g_width + 7) / 8;

    type ram_type is array (g_depth - 1 downto 0) of std_logic_vector(g_width - 1 downto 0);

    -- Initialize RAM from a text file (one binary word per line)
    impure function init_ram_from_file(filename : string) return ram_type is
        file ramfile                                : text open read_mode is filename;
        variable ramfileline                        : line;
        variable ram_v                              : ram_type;
        variable bitvec                             : bit_vector(g_width - 1 downto 0);
    begin
        for i in ram_type'range loop
            readline(ramfile, ramfileline);
            read(ramfileline, bitvec);
            ram_v(i) := to_stdlogicvector(bitvec);
        end loop;
        return ram_v;
    end function;

    -- File init if a filename is given, otherwise all zeros (matches hardware)
    impure function init_ram(filename : string) return ram_type is
    begin
        if filename'length > 0 then
            return init_ram_from_file(filename);
        else
            return (others => (others => '0'));
        end if;
    end function;

    signal ram                 : ram_type := init_ram(g_init_file);
    attribute ram_style        : string;
    attribute ram_style of ram : signal is g_ram_style;
    signal ram_data            : std_logic_vector(g_width - 1 downto 0);
    signal rd_data_reg         : std_logic_vector(g_width - 1 downto 0) := (others => '0');

begin
    assert g_performance = "LOW_LATENCY" or g_performance = "HIGH_PERFORMANCE"
    report "g_performance must be ""LOW_LATENCY"" or ""HIGH_PERFORMANCE"""
        severity failure;

    -- Read port
    p_read : process (clk)
    begin
        if rising_edge(clk) then
            if rd_ena = '1' then
                ram_data <= ram(to_integer(unsigned(rd_addr)));
            end if;
        end if;
    end process p_read;

    p_write : process (clk)
        variable v_hi : natural;
    begin
        if rising_edge(clk) then
            if wr_ena = '1' then
                for i in 0 to c_width_bytes - 1 loop
                    if wr_be(i) = '1' then
                        v_hi := minimum((i + 1) * 8, g_width) - 1; -- clamp the last lane
                        ram(to_integer(unsigned(wr_addr)))(v_hi downto i * 8)
                        <= wr_data(v_hi downto i * 8);
                    end if;
                end loop;
            end if;
        end if;
    end process p_write;

    -- LOW_LATENCY: no output register (1 cycle read latency, longer clock-to-out)
    g_no_output_register : if g_performance = "LOW_LATENCY" generate
        rd_data <= ram_data;
    end generate g_no_output_register;

    -- HIGH_PERFORMANCE: output register (2 cycle read latency, better clock-to-out)
    g_output_register : if g_performance = "HIGH_PERFORMANCE" generate
        p_out_reg : process (clk)
        begin
            if rising_edge(clk) then
                if reset = '1' then
                    rd_data_reg <= (others => '0');
                elsif rd_regce = '1' then
                    rd_data_reg <= ram_data;
                end if;
            end if;
        end process p_out_reg;

        rd_data <= rd_data_reg;
    end generate g_output_register;
end architecture behavior;