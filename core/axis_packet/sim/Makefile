SIM=questa-compat
WAVES=1
#GUI=1
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

COCOTB_TOPLEVEL = axis_packet_fifo_sync_dut
COCOTB_TEST_MODULES = axis_packet_fifo_sync_tc

#COCOTB_TOPLEVEL = axis_packet_switch_dut
#COCOTB_TEST_MODULES = axis_packet_switch_tc

export PYTHONPATH=$(abspath ../py_tc):$(abspath ../py_bfm):$(abspath $(IP_ROOT)/make_includes/py_tc)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: view
view:
	vsim -view vsim.wlf
