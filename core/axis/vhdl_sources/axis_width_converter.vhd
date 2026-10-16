--  Title:          axis_large_to_small_width
--  Description:    Entity handling large to small conversion.
--                  Buffers the the input and splits 
--                  into smaller beats.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axis_pkg.all;
use work.util_pkg.all;

entity axis_large_to_small_width is
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        stream_in        : in t_axis;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis;
        stream_out_ready : in std_logic
    );
end entity;

architecture behavior of axis_large_to_small_width is
    constant c_input_bytes  : positive := stream_in.tkeep'length;
    constant c_output_bytes : positive := stream_out.tkeep'length;
    constant c_output_width : positive := stream_out.tdata'length;

    type t_state is (Idle, Data);
    signal state          : t_state;
    signal count          : natural;
    signal byte_count     : natural;

    -- Latch signals
    signal stream_latched : stream_in'subtype;
    signal stream_next    : std_logic;

    signal output_buffer  : stream_in'subtype;
begin
    assert c_input_bytes > c_output_bytes report "Output is greater than input" severity failure;
    assert (c_input_bytes rem c_output_bytes) = 0 report "Input is not a multiple of output" severity failure;
    assert stream_in.tuser'length = stream_out.tuser'length report "User size does not match" severity failure;

    i_axis_input_latch : entity work.axis_input_latch
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => stream_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => stream_latched,
            stream_out_ready => stream_next
        );
    p_state_machine : process (clk)
    begin
        if rising_edge(clk) then
            stream_next <= '0';

            if stream_out_ready = '1' then
                stream_out.tvalid <= '0';
            end if;

            case state is
                when idle =>
                    if stream_latched.tvalid = '1' and (stream_out_ready = '1' or stream_out.tvalid = '0') then
                        output_buffer     <= stream_latched;
                        stream_next       <= '1';

                        stream_out.tvalid <= '1';
                        stream_out.tdata  <= stream_latched.tdata(c_output_width - 1 downto 0);
                        stream_out.tkeep  <= stream_latched.tkeep(c_output_bytes - 1 downto 0);
                        stream_out.tuser  <= stream_latched.tuser;

                        if byte_count + c_output_bytes < keep_to_bytes(stream_latched.tkeep) then
                            stream_out.tlast <= '0';
                            byte_count       <= c_output_bytes;
                            count            <= 1;
                            state            <= data;
                        else
                            stream_out.tlast <= '1'; -- When unaligned, always the last beat
                            state            <= idle;
                        end if;

                    end if;
                when data =>
                    if stream_out_ready = '1' or stream_out.tvalid = '0' then
                        stream_out.tvalid <= '1';
                        stream_out.tdata  <= output_buffer.tdata((count + 1) * c_output_width - 1 downto count * c_output_width);
                        stream_out.tkeep  <= output_buffer.tkeep((count + 1) * c_output_bytes - 1 downto count * c_output_bytes);

                        count             <= count + 1;
                        byte_count        <= byte_count + c_output_bytes;
                        if byte_count + c_output_bytes < keep_to_bytes(output_buffer.tkeep) then
                            state <= data;
                        else
                            stream_out.tlast <= output_buffer.tlast;
                            byte_count       <= 0;
                            count            <= 0;
                            state            <= idle;
                        end if;
                    end if;
            end case;

            if reset = '1' then
                stream_next       <= '0';
                stream_out.tvalid <= '0';

                count             <= 0;
                byte_count        <= 0;
                state             <= idle;
            end if;
        end if;
    end process;
end architecture;

--  Title:          axis_small_to_large_width
--  Description:    Entity handling small to large conversion.
--                  Buffers the correct amount of beats and
--                  converts to the new bus.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axis_pkg.all;

entity axis_small_to_large_width is
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        stream_in        : in t_axis;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis;
        stream_out_ready : in std_logic
    );
end entity;

architecture behavior of axis_small_to_large_width is
    constant c_input_width  : positive := stream_in.tdata'length;
    constant c_input_bytes  : positive := stream_in.tkeep'length;
    constant c_output_bytes : positive := stream_out.tkeep'length;
    constant c_num_beats    : positive := c_output_bytes / c_input_bytes;

    type t_stream_array is array(natural range <>) of stream_in'subtype;

    function stream_array_to_axis(input : t_stream_array) return stream_out'subtype is
        variable v_stream                   : stream_out'subtype;
    begin
        v_stream        := axis_init(v_stream);
        v_stream.tuser  := input(0).tuser;
        v_stream.tvalid := '1';

        for index in input'reverse_range loop
            v_stream.tkeep((index + 1) * c_input_bytes - 1 downto index * c_input_bytes) := input(index).tkeep;
            v_stream.tdata((index + 1) * c_input_width - 1 downto index * c_input_width) := input(index).tdata;

            if input(index).tlast = '1' then
                v_stream.tlast := '1';
                exit;
            end if;
        end loop;

        return v_stream;
    end function;

    -- Latch signals
    signal stream_latched      : stream_in'subtype;
    signal stream_next         : std_logic;

    -- Input signals
    signal input_buffer        : t_stream_array(c_num_beats - 2 downto 0); -- need one less
    signal count               : integer;
    signal output_buffer_valid : std_logic;
    signal output_buffer       : t_stream_array(c_num_beats - 1 downto 0);

    -- Output signals
    signal control_valid       : std_logic;
    signal control_ready       : std_logic;
begin
    assert c_output_bytes > c_input_bytes report "Input is greater than output" severity failure;
    assert (c_output_bytes rem c_input_bytes) = 0 report "Output is not a multiple of input" severity failure;
    assert stream_in.tuser'length = stream_out.tuser'length report "User size does not match" severity failure;

    i_axis_input_latch : entity work.axis_input_latch
        port map(
            clk              => clk,
            reset            => reset,
            stream_in        => stream_in,
            stream_in_ready  => stream_in_ready,
            stream_out       => stream_latched,
            stream_out_ready => stream_next
        );

    p_input_reg : process (clk)
    begin
        if rising_edge(clk) then
            stream_next         <= '0';
            output_buffer_valid <= '0';

            if stream_latched.tvalid = '1' then
                if count < c_num_beats - 1 and stream_in.tlast = '0' then
                    input_buffer(count) <= stream_latched;

                    count               <= count + 1;
                    stream_next         <= '1';
                else
                    input_buffer                      <= (others => axis_init(stream_latched));

                    output_buffer(input_buffer'range) <= input_buffer;
                    output_buffer(count)              <= stream_latched;
                    output_buffer_valid               <= '1';

                    if control_ready = '1' then
                        count       <= 0;
                        stream_next <= '1';
                    end if;
                end if;
            end if;

            if reset = '1' then
                count <= 0;
            end if;
        end if;
    end process;

    control_ready <= stream_out_ready or not control_valid;

    p_output_reg : process (clk)
    begin
        if rising_edge(clk) then
            control_valid <= '0';

            if stream_out_ready = '1' then
                stream_out.tvalid <= '0';
            end if;

            if output_buffer_valid = '1' and (stream_out_ready = '1' or stream_out.tvalid = '0') then
                stream_out        <= stream_array_to_axis(output_buffer);
                stream_out.tvalid <= '1';
                control_valid     <= '1';
            end if;

            if reset = '1' then
                control_valid     <= '0';
                stream_out.tvalid <= '0';
            end if;
        end if;
    end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axis_pkg.all;
use work.math_pkg.all;

entity axis_width_converter is
    port (
        clk              : in std_logic;
        reset            : in std_logic;

        stream_in        : in t_axis;
        stream_in_ready  : out std_logic;

        stream_out       : out t_axis;
        stream_out_ready : in std_logic
    );
end entity;

architecture structure of axis_width_converter is
    constant c_input_bytes  : positive := stream_in.tkeep'length;
    constant c_output_bytes : positive := stream_out.tkeep'length;

    constant gcd            : natural  := gcd(c_input_bytes, c_output_bytes);

    -- In case of relative primes
    constant c_mid_bytes    : positive := c_input_bytes * c_output_bytes;
    signal stream_mid       : t_axis(tdata(c_mid_bytes * 8 - 1 downto 0), tkeep(c_mid_bytes - 1 downto 0), tuser(stream_in.tuser'range));
    signal stream_mid_ready : std_logic;
begin
    assert (gcd /= 1 or (c_input_bytes = 1 or c_output_bytes = 1)) report "Error: bus size cannot be prime" severity failure;

    g_generate_up_converter : if c_input_bytes <= c_output_bytes generate
        i_up_converter : entity work.axis_small_to_large_width
            port map(
                clk              => clk,
                reset            => reset,
                stream_in        => stream_in,
                stream_in_ready  => stream_in_ready,
                stream_out       => stream_out,
                stream_out_ready => stream_out_ready
            );

    end generate;
    g_generate_down_converter : if c_input_bytes > c_output_bytes generate
        i_down_converter : entity work.axis_large_to_small_width
            port map(
                clk              => clk,
                reset            => reset,
                stream_in        => stream_in,
                stream_in_ready  => stream_in_ready,
                stream_out       => stream_out,
                stream_out_ready => stream_out_ready
            );

    end generate;
end architecture;