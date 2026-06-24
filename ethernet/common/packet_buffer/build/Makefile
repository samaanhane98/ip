SIM ?= questa
GUI=1

TOPLEVEL_LANG ?= vhdl
IP_ROOT = ../../../..

COMPILE_ARGS += -2008
# PATH := /tools/Questa/questa_fse/bin:$(PATH)
# export PATH

VHDL_SOURCES += $(wildcard $(IP_ROOT)/packages/vhdl_sources/*.vhd)
VHDL_SOURCES += $(wildcard $(IP_ROOT)/common/buffers/vhdl_sources/*.vhd)
# VHDL_SOURCES += $(wildcard $(IP_ROOT)/ethernet/common/packet_buffer/vhdl_sources/*.vhd)
VHDL_SOURCES += $(wildcard ../vhdl_sources/*.vhd)

export PYTHONPATH :=../sim:$(wildcard $(IP_ROOT)/bfm/sim)

COCOTB_TOPLEVEL = packet_input_buffer
COCOTB_TEST_MODULES = packet_input_buffer_tc

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
