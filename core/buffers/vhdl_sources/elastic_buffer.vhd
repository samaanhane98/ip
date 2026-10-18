library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;

entity elastic_buffer is
    generic (
        g_ram_style         : string    := "auto";
        g_ram_behavior      : string    := "RBW";
        g_ready_reset_state : std_logic := '1'
    );
    port (
        -- Input interface
        wr_clk   : in std_logic;
        wr_reset : in std_logic;
        wr_data  : in std_logic_vector(7 downto 0);
        wr_valid : in std_logic;

        -- Output Interface
        rd_clk   : in std_logic;
        rd_reset : in std_logic;
        rd_data  : out std_logic_vector(7 downto 0);
        rd_valid : out std_logic
    );
end entity;

architecture structure of elastic_buffer is
    constant c_min_ipg            : positive := 12;
    constant c_depth              : positive := 32;
    constant c_almost_full_bound  : positive := 24;
    constant c_almost_empty_bound : positive := 8;
    constant c_setpoint           : positive := 10;

    -- Write state machine signals
    type t_wr_state is (wait_for_idle, write);
    signal wr_state      : t_wr_state;
    signal control_valid : std_logic;
    signal wr_idle_count : natural;
    signal idle_deleted  : std_logic;
    signal allow_delete  : std_logic;

    -- Read state machine signals
    type t_rd_state is (pre_fill, read);
    signal rd_state        : t_rd_state;
    signal control_ready   : std_logic;
    signal idle_inserted   : std_logic;
    signal allow_insert    : std_logic;

    -- FIFO signals
    signal fifo_data_out   : rd_data'subtype;
    signal fifo_data_valid : std_logic;
    signal fifo_rd_level   : std_logic_vector(log2ceil(c_depth + 1) - 1 downto 0);
    signal wr_almost_full  : std_logic;
    signal rd_almost_empty : std_logic;
    signal fifo_valid      : std_logic;

begin
    p_write_state : process (wr_clk)
    begin
        if rising_edge(wr_clk) then
            case wr_state is
                when wait_for_idle =>
                    if wr_valid = '0' then
                        wr_state <= write;
                    end if;
                when write =>
                    if wr_valid = '0' then
                        if wr_idle_count < c_min_ipg then
                            wr_idle_count <= wr_idle_count + 1;
                        end if;
                        if control_valid = '0' then
                            idle_deleted <= '1';
                        end if;
                    else
                        wr_idle_count <= 0;
                        idle_deleted  <= '0';
                    end if;
            end case;

            if wr_reset = '1' then
                wr_idle_count <= 0;
                idle_deleted  <= '0';
                wr_State      <= wait_for_idle;
            end if;
        end if;
    end process;

    allow_delete <= '1' when wr_idle_count = c_min_ipg and idle_deleted = '0' else
        '0';
    control_valid <= '0' when wr_state = wait_for_idle else
        wr_valid or not (wr_almost_full and allow_delete);

    i_olo_base_fifo_async : entity work.olo_base_fifo_async
        generic map(
            Width_g         => wr_data'length + 1,
            Depth_g         => c_depth,
            RamStyle_g      => g_ram_style,
            RamBehavior_g   => g_ram_behavior,
            AlmFullOn_g     => true,
            AlmFullLevel_g  => c_almost_full_bound,
            AlmEmptyOn_g    => true,
            AlmEmptyLevel_g => c_almost_empty_bound
        )
        port map(
            -- Input interface
            In_Clk               => wr_clk,
            In_Rst               => wr_reset,
            In_RstOut            => open,
            In_Data              => wr_valid & wr_data,
            In_Valid             => control_valid,
            In_Ready             => open,
            In_AlmFull           => wr_almost_full,

            -- Output Interface
            Out_Clk              => rd_clk,
            Out_Rst              => rd_reset,
            Out_RstOut           => open,
            Out_Data(7 downto 0) => fifo_data_out,
            Out_Data(8)          => fifo_data_valid,
            Out_Valid            => fifo_valid,
            Out_Ready            => control_ready,
            Out_AlmEmpty         => rd_almost_empty,
            Out_Level            => fifo_rd_level
        );

    rd_data      <= fifo_data_out;
    rd_valid     <= fifo_valid and fifo_data_valid and control_ready;

    allow_insert <= '1' when idle_inserted = '0' else
        '0';
    control_ready <= '0' when rd_state = pre_fill else
        fifo_data_valid or not (rd_almost_empty and allow_insert);

    p_read_state : process (rd_clk)
    begin
        if rising_edge(rd_clk) then
            case rd_state is
                when pre_fill =>
                    if fifo_valid = '1' and unsigned(fifo_rd_level) > c_setpoint then
                        rd_state <= read;
                    end if;
                when read =>
                    if fifo_valid = '1' then
                        if fifo_data_valid = '0' then
                            if control_ready = '0' then
                                idle_inserted <= '1';
                            end if;
                        else
                            idle_inserted <= '0';
                        end if;
                    end if;
            end case;

            if rd_reset = '1' then
                idle_inserted <= '0';
                rd_state      <= pre_fill;
            end if;
        end if;
    end process;
end architecture;