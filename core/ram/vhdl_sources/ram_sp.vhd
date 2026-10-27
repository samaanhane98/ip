library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.math_pkg.all;

entity ram_sp is
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

        addr     : in std_logic_vector(log2ceil(g_depth) - 1 downto 0);
        ena      : in std_logic;
        wr_ena   : in std_logic;
        wr_data  : in std_logic_vector(g_width - 1 downto 0);

        rd_regce : in std_logic := '1';
        rd_data  : out std_logic_vector(g_width - 1 downto 0)
    );
end entity ram_sp;