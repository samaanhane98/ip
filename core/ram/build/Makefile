SIM=questa

COMPILE_ARGS += -2008 +acc

TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../..

VHDL_SOURCES = $(IP_ROOT)/core/packages/math_pkg.vhd
VHDL_SOURCES += $(IP_ROOT)/core/ram/vhdl_sources/ram_sdp.vhd

export PYTHONPATH=../sim

COCOTB_TOPLEVEL = ram_sdp
COCOTB_TEST_MODULES =ram_sdp_tc

SIM_ARGS += -do dump_waves.do

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

#clean:
#	rm qrun.log;
#	rm results.xml;
#	rm -rf sim_build;
#	rm transcript;
#	rm waveform.*;