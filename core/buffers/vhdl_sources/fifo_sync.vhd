library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.math_pkg.all;

entity fifo_sync is
    generic (
        g_width              : POSITIVE  := 32;
        g_depth              : POSITIVE  := 32;
        g_almost_full_ena    : BOOLEAN   := false;
        g_almost_full_level  : natural   := 0;
        g_almost_empty_ena   : BOOLEAN   := false;
        g_almost_empty_level : natural   := 0;
        g_ram_style          : string    := "auto";
        g_ram_behavior       : string    := "RBW";
        g_ready_reset_state  : STD_LOGIC := '1'
    );
    port (
        -- Input interface
        clk          : in  std_logic;
        reset        : in  std_logic;

        wr_data      : in  std_logic_vector(g_width - 1 downto 0);
        wr_valid     : in  std_logic := '1';
        wr_ready     : out std_logic;
        wr_level     : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);

        -- Output Interface
        rd_data      : out std_logic_vector(g_width - 1 downto 0);
        rd_valid     : out std_logic;
        rd_ready     : in  std_logic := '1';
        rd_level     : out std_logic_vector(log2ceil(g_depth + 1) - 1 downto 0);

        -- Output Status
        full         : out std_logic;
        empty        : out std_logic;
        almost_full  : out std_logic;
        almost_empty : out std_logic

    );
end entity;

architecture structure of fifo_sync is
begin
    i_olo_base_fifo_sync: entity work.olo_base_fifo_sync
        generic map (
            Width_g         => g_width,
            Depth_g         => g_depth,
            AlmFullOn_g     => g_almost_full_ena,
            AlmFullLevel_g  => g_almost_full_level,
            AlmEmptyOn_g    => g_almost_empty_ena,
            AlmEmptyLevel_g => g_almost_empty_level,
            RamStyle_g      => g_ram_style,
            RamBehavior_g   => g_ram_behavior,
            ReadyRstState_g => g_ready_reset_state
        )
        port map (
            -- Input interface
            Clk       => clk,
            Rst       => reset,
            In_Data   => wr_data,
            In_Valid  => wr_valid,
            In_Ready  => wr_ready,
            In_Level  => wr_level,
            -- Output Interface
            Out_Data  => rd_data,
            Out_Valid => rd_valid,
            Out_Ready => rd_ready,
            Out_Level => rd_level,
            -- Output 
            Full      => full,
            Empty     => empty,
            AlmFull   => almost_full,
            AlmEmpty  => almost_empty
        );
end architecture;
