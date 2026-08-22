library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

	use work.math_pkg.all;

entity fifo_async is
	generic (
		g_width: POSITIVE := 32;
		g_depth: POSITIVE := 32;
		g_almost_full_ena: BOOLEAN := false;
		g_almost_full_level: natural := 0;
		g_almost_empty_ena: BOOLEAN := false;
		g_almost_empty_level: natural := 0;
		g_ram_style: string := "auto";
		g_ram_behavior: string := "RBW";
		g_ready_reset_state: STD_LOGIC := '1';
		g_optimization: string := "SPEED";
		g_sync_stages: POSITIVE range 2 to 4 := 2
	);
	port (
        -- Input interface
        wr_clk          : in    std_logic;
        wr_reset          : in    std_logic;

        wr_data         : in    std_logic_vector(g_width-1 downto 0);
        wr_valid        : in    std_logic := '1';
        wr_ready        : out   std_logic;

        -- Input Status
        wr_full         : out   std_logic;
        wr_empty        : out   std_logic;
        wr_almost_full      : out   std_logic;
        wr_almost_empty     : out   std_logic;
        wr_level        : out   std_logic_vector(log2ceil(g_depth+1)-1 downto 0);

        -- Output Interface
        rd_clk         : in    std_logic;
        rd_reset         : in    std_logic;
        rd_data        : out   std_logic_vector(g_width-1 downto 0);
        rd_valid       : out   std_logic;
        rd_ready       : in    std_logic := '1';

        -- Output Status
        rd_full        : out   std_logic;
        rd_empty       : out   std_logic;
        rd_almost_full     : out   std_logic;
        rd_almost_empty    : out   std_logic;
        rd_level       : out   std_logic_vector(log2ceil(g_depth+1)-1 downto 0)
			
	);
end entity;

architecture structure of fifo_async is

begin
	i_olo_base_fifo_async: entity work.olo_base_fifo_async
		generic map (
			Width_g         => g_width,
			Depth_g         => g_depth,
			AlmFullOn_g     => g_almost_full_ena,
			AlmFullLevel_g  => g_almost_full_level,
			AlmEmptyOn_g    => g_almost_empty_ena,
			AlmEmptyLevel_g => g_almost_empty_level,
			RamStyle_g      => g_ram_style,
			RamBehavior_g   => g_ram_behavior,
			ReadyRstState_g => g_ready_reset_state,
			Optimization_g  => g_optimization,
			SyncStages_g    => g_sync_stages
		)
		port map (
			-- Input interface
			In_Clk          => wr_clk,
			In_Rst          => wr_reset,
			In_RstOut       => open,
			In_Data         => wr_data,
			In_Valid        => wr_valid,
			In_Ready        => wr_ready,
			-- Input Status
			In_Full         => wr_full,
			In_Empty        => wr_empty,
			In_AlmFull      => wr_almost_full,
			In_AlmEmpty     => wr_almost_empty,
			In_Level        => wr_level,
			-- Output Interface
			Out_Clk         => rd_clk,
			Out_Rst         => rd_reset,
			Out_RstOut      => open,
			Out_Data        => rd_data,
			Out_Valid       => rd_valid,
			Out_Ready       => rd_ready,
			-- Output Status
			Out_Full        => rd_full,
			Out_Empty       => rd_empty,
			Out_AlmFull     => rd_almost_full,
			Out_AlmEmpty    => rd_almost_empty,
			Out_Level       => rd_level
		);
end architecture;