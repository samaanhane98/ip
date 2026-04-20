SIM ?= ghdl
SIM_ARGS ?= --vcd=waveform.vcd

COMPILE_ARGS ?= --std=08


TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../..

VHDL_SOURCES += $(wildcard $(IP_ROOT)/packages/vhdl_sources/*.vhd)
VHDL_SOURCES += $(wildcard $(IP_ROOT)/components/buffers/vhdl_sources/*.vhd)
VHDL_SOURCES += $(wildcard $(IP_ROOT)/components/buffers/vhdl_sim/*.vhd)

export PYTHONPATH=../sim

COCOTB_TOPLEVEL = axi4s_output_buffer_wrapper
COCOTB_TEST_MODULES =axi4s_output_buffer_tc

# COCOTB_TOPLEVEL = axi4s_input_buffer_wrapper
# COCOTB_TEST_MODULES =axi4s_input_buffer_tc


GHDL_ARGS = --std=08

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim