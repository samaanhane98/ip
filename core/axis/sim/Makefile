SIM=questa-compat
COMPILE_ARGS += -2008 +acc
TOPLEVEL_LANG ?= vhdl

IP_ROOT = ../../..

VHDL_SOURCES =

# Open-logic
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_pkg_array.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_pkg_math.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_pkg_logic.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_pkg_string.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_pkg_attribute.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_ram_sdp.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_cc_bits.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_cc_reset.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_fifo_async.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/modules/open-logic/src/base/vhdl/olo_base_fifo_sync.vhd)

VHDL_SOURCES += $(abspath $(IP_ROOT)/core/packages/vhdl_sources/*.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/core/buffers/vhdl_sources/*.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/core/ram/vhdl_sources/*.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/core/axis/vhdl_sources/*.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/core/axis/vhdl_sim/*.vhd)

export PYTHONPATH=$(abspath ../py_tc):$(abspath ../py_bfm):$(abspath $(IP_ROOT)/make_includes/py_tc)

MODULES :=

MODULE			:= axis_fifo_sync_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_fifo_sync_dut
$(MODULE)_TEST 	= axis_fifo_sync_tc

# Broken
#MODULE			:= axis_fifo_async_tc
#MODULES 		+= $(MODULE)
#$(MODULE)_DUT 	= axis_fifo_async_dut
#$(MODULE)_TEST 	= axis_fifo_async_tc

MODULE			:= axis_switch_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_switch_dut
$(MODULE)_TEST 	= axis_switch_tc

MODULE			:= axis_arbiter_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_arbiter_dut
$(MODULE)_TEST 	= axis_arbiter_tc

MODULE			:= axis_input_latch_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_input_latch_dut
$(MODULE)_TEST 	= axis_input_latch_tc

MODULE			:= axis_width_converter_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_width_converter_dut
$(MODULE)_TEST 	= axis_width_converter_tc

MODULE			:= axis_queue_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_queue_dut
$(MODULE)_TEST 	= axis_queue_tc

include $(abspath $(IP_ROOT)/make_includes/sim/Makefile)