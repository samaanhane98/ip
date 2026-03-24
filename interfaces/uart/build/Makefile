SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd


TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../../

VHDL_SOURCES += $(IP_ROOT)/interfaces/uart/vhdl_sources/uart_rx.vhd
VHDL_SOURCES += $(IP_ROOT)/interfaces/uart/vhdl_sources/uart_tx.vhd
VHDL_SOURCES += $(IP_ROOT)/interfaces/uart/vhdl_sources/uart_timing_gen.vhd
VHDL_SOURCES += $(IP_ROOT)/components/input_sync/vhdl_sources/input_sync.vhd

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = uart_rx

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
export PYTHONPATH=../sim
COCOTB_TEST_MODULES =uart_rx_tc

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
