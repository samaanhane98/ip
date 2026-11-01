library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.axis_pkg.all;
use work.math_pkg.all;

entity axis_queue is
    generic (
        g_drop_on_full : boolean := true;
        g_data_depth   : natural := 32;
        g_ram_style    : string  := "auto"
    );
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        drop             : in std_logic;

        stream_in        : in t_axis;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis;
        stream_out_ready : in std_logic
    );
end entity;

architecture structure of axis_queue is
    constant c_address_width : natural := log2ceil(g_data_depth);
    type t_write_state is (write_data, drop_data);
    signal wr_state : t_write_state;

    -- Latch signals
    subtype t_latch_packet is t_axis(tdata(stream_in.tdata'range), tkeep(stream_in.tkeep'range), tuser(stream_in.tuser'length downto 0)); -- add drop
    signal stream_latch_in       : t_latch_packet;
    signal stream_latched        : t_latch_packet;
    signal stream_next           : std_logic;
    signal stream_drop           : std_logic;

    signal commit_address        : unsigned(c_address_width - 1 downto 0);

    -- Queue signals
    signal control_write_address : unsigned(c_address_width - 1 downto 0);
    signal control_write_data    : std_logic_vector(get_size(stream_latched) - 1 downto 0);
    signal control_write_ena     : std_logic;
    signal control_read_address  : control_write_address'subtype;
    signal control_read_data     : control_write_data'subtype;

begin
    assert 2 ** integer(round(log2(real(g_data_depth)))) = g_data_depth report "Depth not a power of 2" severity failure;

    stream_latch_in.tvalid <= stream_in.tvalid;
    stream_latch_in.tlast  <= stream_in.tlast;
    stream_latch_in.tdata  <= stream_in.tdata;
    stream_latch_in.tkeep  <= stream_in.tkeep;
    stream_latch_in.tuser  <= drop & stream_in.tuser;

    i_data_latch : entity work.axis_input_latch
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => stream_latch_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => stream_latched,
            stream_out_ready => stream_next
        );

    b_write          : block

        signal full_drop : std_logic;
        signal discard   : std_logic;
        signal overflow  : std_logic;
        signal full      : std_logic;
    begin

        stream_drop        <= stream_latched.tuser(stream_latched.tuser'left);
        full               <= '1' when control_write_address + 1 = control_read_address else '0';
        full_drop          <= full when g_drop_on_full else '0';
        overflow           <= '1' when full = '1' and control_write_address /= commit_address and control_read_address = commit_address else '0';
        discard            <= stream_drop or overflow or full_drop; -- Note: overflow results in a deadlock so we must always drop

        control_write_ena  <= stream_latched.tvalid and not discard;
        control_write_data <= pack(stream_latched);

        p_write : process (clk)
        begin
            if rising_edge(clk) then
                stream_next <= '0';

                case wr_state is
                    when write_data =>
                        if stream_latched.tvalid = '1' then
                            if discard = '1' then
                                stream_next           <= '1';
                                control_write_address <= commit_address;

                                if stream_latched.tlast = '0' then
                                    wr_state <= drop_data;
                                end if;

                            elsif full = '0' then
                                stream_next           <= '1';
                                control_write_address <= control_write_address + 1;

                                if stream_latched.tlast = '1' then
                                    commit_address <= control_write_address + 1;
                                end if;
                            end if;
                        end if;

                    when drop_data =>
                        stream_next <= '1';

                        if stream_latched.tvalid = '1' and stream_latched.tlast = '1' then
                            wr_state <= write_data;
                        end if;
                end case;

                if reset = '1' then
                    control_write_address <= (others => '0');
                    commit_address        <= (others => '0');
                    stream_next           <= '0';
                end if;
            end if;
        end process;
    end block;

    i_queue : entity work.ram_sdp
        generic map(
            g_width       => control_write_data'length,
            g_depth       => g_data_depth,
            g_ram_style   => g_ram_style,
            g_performance => "LOW_LATENCY"
        )
        port map(
            clk      => clk,
            reset    => reset,
            wr_addr  => std_logic_vector(control_write_address),
            wr_data  => control_write_data,
            wr_ena   => control_write_ena,
            rd_addr  => std_logic_vector(control_read_address),
            rd_ena   => '1',
            rd_regce => '1',
            rd_data  => control_read_data
        );

    b_read                : block
        signal load           : std_logic;
        signal no_full_packet : std_logic;
        signal rd_addr_next   : unsigned(control_read_address'range);
        signal commit_rd      : unsigned(commit_address'range); -- see note below

    begin
        no_full_packet       <= '1' when rd_addr_next = commit_rd else '0';
        load                 <= '1' when no_full_packet = '0' and (stream_out.tvalid = '0' or stream_out_ready = '1') else '0';
        control_read_address <= rd_addr_next + 1 when load = '1' else rd_addr_next;

        p_handle_read : process (clk)
            variable v_output : t_latch_packet;
        begin
            if rising_edge(clk) then
                commit_rd <= commit_address;

                if stream_out_ready = '1' then
                    stream_out.tvalid <= '0';
                end if;

                if load = '1' then
                    v_output := unpack(control_read_data, v_output);
                    stream_out.tvalid <= '1';
                    stream_out.tlast  <= v_output.tlast;
                    stream_out.tdata  <= v_output.tdata;
                    stream_out.tkeep  <= v_output.tkeep;
                    stream_out.tuser  <= v_output.tuser(stream_out.tuser'range);
                end if;

                rd_addr_next <= control_read_address;

                if reset = '1' then
                    rd_addr_next <= (others => '0');
                    commit_rd            <= (others => '0');
                    stream_out.tvalid    <= '0';
                end if;
            end if;
        end process;
    end block;
end architecture;