SIM=questa
WAVES=1
SIM_ARGS += -do dump_waves.do
COMPILE_ARGS += -2008 +acc
TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../..

VHDL_SOURCES = $(IP_ROOT)/core/packages/math_pkg.vhd
VHDL_SOURCES += $(IP_ROOT)/core/buffers/vhdl_sources/fifo_sync.vhd
VHDL_SOURCES += $(IP_ROOT)/modules/open-logic/src/base/vhdl/*.vhd

COCOTB_TOPLEVEL = fifo_sync
COCOTB_TEST_MODULES =fifo_sync_tc

#VHDL_SOURCES = $(IP_ROOT)/core/packages/math_pkg.vhd
#VHDL_SOURCES += $(IP_ROOT)/core/buffers/vhdl_sources/fifo_async.vhd
#VHDL_SOURCES += $(IP_ROOT)/modules/open-logic/src/base/vhdl/*.vhd

#COCOTB_TOPLEVEL = fifo_async
#COCOTB_TEST_MODULES =fifo_async_tc


export PYTHONPATH= ../py_tc:$(abspath $(IP_ROOT)/make_includes/python)
# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: view
view:
	@if [ -f waveform.vcd ]; then \
		vcd2wlf waveform.vcd waveform.wlf; \
		vsim -view waveform.wlf; \
	else \
		echo "waveform.vcd not found — run 'make sim' first."; \
	fi
