SIM=questa-compat
GUI=1

COMPILE_ARGS += -2008
VSIM_ARGS += -voptargs=+acc -do "log -r /*; add wave -r /*"

TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../..

VHDL_SOURCES = $(IP_ROOT)/core/packages/axis_pkg.vhd
VHDL_SOURCES += $(IP_ROOT)/core/components/vhdl_sources/axis_fifo_sync.vhd
VHDL_SOURCES += $(IP_ROOT)/core/components/vhdl_sim/axis_fifo_sync_wrapper.vhd

export PYTHONPATH=../sim

COCOTB_TOPLEVEL = axis_fifo_sync_wrapper
COCOTB_TEST_MODULES =axis_fifo_sync_tc

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim