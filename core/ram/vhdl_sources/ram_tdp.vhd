library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.math_pkg.all;

entity ram_tdp is
    generic (
        g_width       : natural := 32;
        g_depth       : natural := 1024;
        g_performance : string  := "HIGH_PERFORMANCE";
        g_ram_style   : string  := "auto"; -- auto, block, distributed
        g_init_file   : string  := ""
    );
    port (
        clk         : in  std_logic;

        -- Port A
        a_addr      : in  std_logic_vector(log2ceil(g_depth) - 1 downto 0);
        a_ena       : in  std_logic;
        a_wr_ena    : in  std_logic;
        a_wr_data   : in  std_logic_vector(g_width - 1 downto 0);
        a_reset     : in  std_logic;
        a_regce     : in  std_logic := '1';
        a_rd_data   : out std_logic_vector(g_width - 1 downto 0);

        -- Port B
        b_addr      : in  std_logic_vector(log2ceil(g_depth) - 1 downto 0);
        b_ena       : in  std_logic;
        b_wr_ena    : in  std_logic;
        b_wr_data   : in  std_logic_vector(g_width - 1 downto 0);
        b_reset     : in  std_logic;
        b_regce     : in  std_logic := '1';
        b_rd_data   : out std_logic_vector(g_width - 1 downto 0)
    );
end entity ram_tdp;