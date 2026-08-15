library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library UNISIM;
    use UNISIM.VComponents.all;

entity mdio is
    generic (
        g_mdc_half_period : integer := 32
    );
    port (
        clk                : in    std_logic;
        reset              : in    std_logic;

        -- '0' = read_request, '1' = write_request
        op                 : in    std_logic;
        phy_addr           : in    std_logic_vector(4 downto 0);
        reg_addr           : in    std_logic_vector(4 downto 0);
        data               : in    std_logic_vector(15 downto 0);

        ena                : in    std_logic;
        busy               : out   std_logic;
        valid              : out   std_logic;
        resp               : out   std_logic_vector(15 downto 0);

        -- MDIO interface
        mdc                : out   std_logic;
        mdio_io            : inout std_logic
    );
end entity;

architecture behavior of mdio is
    type t_state is (idle, preamble, start, operation, phy_address, reg_address, turn_around_read, turn_around_write, read_response, write_response);
    signal state : t_state;

    ---- MSB first
    signal phy_addr_latched : std_logic_vector(4 downto 0);
    signal reg_addr_latched : std_logic_vector(4 downto 0);
    signal data_latched     : std_logic_vector(15 downto 0);

    signal op_latched : std_logic;
    signal op_bits    : std_logic_vector(1 downto 0);

    signal mdc_count  : unsigned(7 downto 0);
    signal mdc_fe     : std_logic;
    signal mdc_sample : std_logic;

    signal bit_count : integer;

    signal data_srl : std_logic_vector(15 downto 0);

    signal data_from_mdio : std_logic;
    signal data_to_mdio   : std_logic;
    signal mdio_tri       : std_logic;
begin
    busy <= '0' when state = idle else '1';

    i_mdio_clock: entity work.mdio_clock
        generic map (
            g_mdc_half_period => g_mdc_half_period
        )
        port map (
            clk        => clk,
            reset      => reset,
            mdc        => mdc,
            mdc_fe     => mdc_fe,
            mdc_sample => mdc_sample,
            mdc_count  => mdc_count
        );

    p_state_machine: process (clk)
    begin
        if rising_edge(clk) then
            case state is
                when idle =>
                    if ena = '1' then
                        if mdc_sample = '1' then
                            phy_addr_latched <= phy_addr;
                            reg_addr_latched <= reg_addr;
							data_latched <= data;
                            op_latched <= op;

                            if op = '0' then
                                op_bits <= "10";
                            else
                                op_bits <= "01";
                            end if;

                            valid <= '0';
                            state <= preamble;
                        end if;
                    end if;

                    bit_count <= 0;
                    mdio_tri <= '1';
                when preamble =>
                    if mdc_sample = '1' then
                        if bit_count = 31 then
                            state <= start;
                        end if;

                        bit_count <= bit_count + 1;

                        data_to_mdio <= '1';
                        mdio_tri <= '0';
                    end if;
                when start =>
                    if mdc_sample = '1' then
                        if bit_count = 32 then
                            data_to_mdio <= '0';
                        else
                            data_to_mdio <= '1';
                            state <= operation;
                        end if;

                        bit_count <= bit_count + 1;
                        mdio_tri <= '0';
                    end if;
                when operation =>
                    if mdc_sample = '1' then
                        if bit_count = 34 then
                            data_to_mdio <= op_bits(1);
                        else
                            data_to_mdio <= op_bits(0);
                            state <= phy_address;
                        end if;

                        bit_count <= bit_count + 1;
                        mdio_tri <= '0';
                    end if;
                when phy_address =>
                    if mdc_sample = '1' then
                        if bit_count = 40 then
                            state <= reg_address;
                        end if;

                        phy_addr_latched <= phy_addr_latched(phy_addr_latched'high - 1 downto 0) & '0';
                        data_to_mdio <= phy_addr_latched(phy_addr_latched'high);

                        bit_count <= bit_count + 1;
                        mdio_tri <= '0';
                    end if;
                when reg_address =>
                    if mdc_sample = '1' then
                        if bit_count = 45 then
                            state <= turn_around_read when op_latched = '0' else turn_around_write;
                        end if;

                        reg_addr_latched <= reg_addr_latched(reg_addr_latched'high - 1 downto 0) & '0';
                        data_to_mdio <= reg_addr_latched(reg_addr_latched'high);

                        bit_count <= bit_count + 1;
                        mdio_tri <= '0';
                    end if;
                when turn_around_read =>
                    if mdc_sample = '1' then
                        if bit_count = 47 then
                            state <= read_response;
                        end if;

                        bit_count <= bit_count + 1;
                        mdio_tri <= '1';
                    end if;
                when turn_around_write =>
                    if mdc_sample = '1' then
                        if bit_count = 46 then
                            data_to_mdio <= '1';
                        else
                            data_to_mdio <= '0';
                            state <= write_response;
                        end if;

                        bit_count <= bit_count + 1;
                        mdio_tri <= '0';
                    end if;
                when read_response =>
                    if mdc_sample = '1' then
                        if bit_count = 63 then
                            valid <= '1';

                            state <= idle;
                        end if;

                        resp <= resp(resp'high - 1 downto 0) & data_from_mdio;

                        bit_count <= bit_count + 1;
                        mdio_tri <= '1';
                    end if;
                when write_response =>
                    if mdc_sample = '1' then
                        if bit_count = 63 then
                            state <= idle;
                        end if;

                        data_latched <= data_latched(data_latched'high - 1 downto 0) & '0';
                        data_to_mdio <= data_latched(data_latched'high);

                        bit_count <= bit_count + 1;
                        mdio_tri <= '0';
                    end if;
            end case;

            if reset = '1' then
                resp <= (others => '0');
                valid <= '0';
                bit_count <= 0;
                state <= idle;
            end if;
        end if;
    end process;

    IOBUF_inst: IOBUF
        port map (
            O  => data_from_mdio,
            IO => mdio_io,
            I  => data_to_mdio,
            T  => mdio_tri
        );

end architecture;
