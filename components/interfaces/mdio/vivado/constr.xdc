# Example constraints for the AX7A200B

# MDIO
set_property PACKAGE_PIN N13 [get_ports mdc]
set_property IOSTANDARD LVCMOS33 [get_ports mdc]

set_property PACKAGE_PIN P14 [get_ports mdio_io]
set_property IOSTANDARD LVCMOS33 [get_ports mdio_io]

set_property PACKAGE_PIN R14 [get_ports phy_resetn]
set_property IOSTANDARD LVCMOS33 [get_ports phy_resetn]