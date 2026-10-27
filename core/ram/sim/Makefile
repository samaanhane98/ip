SIM=questa-compat
COMPILE_ARGS += -2008 +acc
TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../..

VHDL_SOURCES = $(wildcard $(IP_ROOT)/core/packages/vhdl_sources/*.vhd)
VHDL_SOURCES += $(wildcard ../vhdl_sources/*.vhd)

MODULES :=

MODULE			:= ram_sdp_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= ram_sdp
$(MODULE)_TEST 	= ram_sdp_tc

export PYTHONPATH=$(abspath ../py_tc):$(abspath ../py_bfm):$(abspath $(IP_ROOT)/make_includes/py_tc)

include $(abspath $(IP_ROOT)/make_includes/sim/Makefile)