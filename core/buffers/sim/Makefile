SIM=questa
WAVES=1
SIM_ARGS += -do dump_waves.do
COMPILE_ARGS += -2008 +acc
TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../..

VHDL_SOURCES = $(abspath $(IP_ROOT)/core/packages/*.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/*.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/core/buffers/vhdl_*/*.vhd)

#COCOTB_TOPLEVEL = fifo_sync_dut
#COCOTB_TEST_MODULES = fifo_sync_tc

COCOTB_TOPLEVEL = fifo_async_dut
COCOTB_TEST_MODULES = fifo_async_tc


export PYTHONPATH=$(abspath ../py_tc):$(abspath ../py_bfm):$(abspath $(IP_ROOT)/make_includes/python)
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
