
architecture wf of ram_sp is
 
    type ram_type is array (g_depth - 1 downto 0) of std_logic_vector(g_width - 1 downto 0);
 
    -- Initialize RAM from a text file (one binary word per line)
    impure function init_ram_from_file(filename : string) return ram_type is
        file     ramfile     : text open read_mode is filename;
        variable ramfileline : line;
        variable ram_v       : ram_type;
        variable bitvec      : bit_vector(g_width - 1 downto 0);
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
 
    signal ram         : ram_type := init_ram(g_init_file);
    signal ram_data    : std_logic_vector(g_width - 1 downto 0);
    signal rd_data_reg : std_logic_vector(g_width - 1 downto 0) := (others => '0');
 
    -- Memory implementation style (Vivado attribute)
    attribute ram_style : string;
    attribute ram_style of ram : signal is g_ram_style;
 
begin
 
    assert g_ram_style = "auto" or g_ram_style = "distributed" or g_ram_style = "block"
        report "g_ram_style must be ""auto"", ""distributed"" or ""block"""
        severity failure;
 
    assert g_performance = "LOW_LATENCY" or g_performance = "HIGH_PERFORMANCE"
        report "g_performance must be ""LOW_LATENCY"" or ""HIGH_PERFORMANCE"""
        severity failure;
 
    -- Write-first single port
    p_ram : process (clk)
    begin
        if rising_edge(clk) then
            if ena = '1' then
                if wr_ena = '1' then
                    ram(to_integer(unsigned(addr))) <= wr_data;
                    ram_data                        <= wr_data;
                else
                    ram_data <= ram(to_integer(unsigned(addr)));
                end if;
            end if;
        end if;
    end process p_ram;
 
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
 
end architecture wf;