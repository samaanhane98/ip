# Example constraints for the AX7A200B

# Ports
set_property PACKAGE_PIN V18 [get_ports rxc]
set_property IOSTANDARD LVCMOS33 [get_ports rxc]

set_property PACKAGE_PIN R19 [get_ports rx_ctl]
set_property IOSTANDARD LVCMOS33 [get_ports rx_ctl]

set_property PACKAGE_PIN P19 [get_ports {rd[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rd[0]}]

set_property PACKAGE_PIN U18 [get_ports {rd[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rd[1]}]

set_property PACKAGE_PIN U17 [get_ports {rd[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rd[2]}]

set_property PACKAGE_PIN P17 [get_ports {rd[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rd[3]}]

# Clocks
set sys_clk_pin [get_pins ]
set idelay_ref_clk_pin [get_pins ]

create_clock -name rxc -period 8.0 [get_ports rxc]
create_generated_clock -name sys_clk $sys_clk_pin
create_generated_clock -name idelay_ref_clk $idelay_ref_clk_pin

# CDC
set_clock_groups -group rxc -group sys_clk -asynchronous
set_clock_groups -group idelay_ref_clk -group sys_clk -asynchronous