SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd


TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../../

VHDL_SOURCES += $(IP_ROOT)/components/axis_fifo/vhdl_sources/axis_fifo.vhd

export PYTHONPATH=../sim

COCOTB_TOPLEVEL = axis_fifo
COCOTB_TEST_MODULES =axis_fifo_tc

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
