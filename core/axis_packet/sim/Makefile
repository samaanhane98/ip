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
VHDL_SOURCES += $(abspath $(IP_ROOT)/core/axis/vhdl_sources/*.vhd)
VHDL_SOURCES += $(abspath $(IP_ROOT)/core/axis_packet/vhdl_sources/*.vhd)

VHDL_SOURCES += $(abspath $(IP_ROOT)/core/axis_packet/vhdl_sim/*.vhd)

export PYTHONPATH=$(abspath ../py_tc):$(abspath ../py_bfm):$(abspath $(IP_ROOT)/make_includes/py_tc)

MODULES :=

MODULE			:= axis_packet_fifo_sync_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_packet_fifo_sync_dut
$(MODULE)_TEST 	= axis_packet_fifo_sync_tc

MODULE			:= axis_packet_switch_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_packet_switch_dut
$(MODULE)_TEST 	= axis_packet_switch_tc

MODULE			:= axis_packet_arbiter_tc
MODULES 		+= $(MODULE)
$(MODULE)_DUT 	= axis_packet_arbiter_dut
$(MODULE)_TEST 	= axis_packet_arbiter_tc

include $(abspath $(IP_ROOT)/make_includes/sim/Makefile)