# Makefile
THIS := $(lastword $(MAKEFILE_LIST))

ifeq ($(T),)

# Export Makefile variables they are usable in the sub-process calls
export VHDL_SOURCES
export PYTHONPATH

# Find first module for the GUI command
FIRST_MODULE := $(firstword $(MODULES))

.PHONY: all clean gui $(MODULES)

all: $(MODULES)

gui:
	$(MAKE) -f $(THIS) GUI=1 T=$(FIRST_MODULE) DUT=$($(FIRST_MODULE)_DUT) TEST=$($(FIRST_MODULE)_TEST)

$(MODULES):
	$(MAKE) -f $(THIS) T=$@ DUT=$($@_DUT) TEST=$($@_TEST)

%.sim:
	$(MAKE) -f $(THIS) T=$* DUT=$($*_DUT) TEST=$($*_TEST)

%.gui:
	$(MAKE) -f $(THIS) GUI=1 T=$* DUT=$($*_DUT) TEST=$($*_TEST)

clean::
	rm -rf work results*.xml __pycache__ *.wlf transcript modelsim.ini

help::
	@echo "make: Run all testcases"
	@echo "make [module]: Run [module] testcase without logging (TODO)"
	@echo "make [module].sim: Run [module] testcase with logging"
	@echo "make [module].gui: Run [module] testcase with Questa GUI"
	@echo "make clean: Clean sim directory"
	@echo "make help: Print this message"

else

SIM=questa-compat
WAVES=0
COMPILE_ARGS += -2008 +acc
TOPLEVEL_LANG ?= vhdl

SIM_BUILD = work/work_$(T)

COCOTB_TOPLEVEL     = $(DUT)
COCOTB_TEST_MODULES = $(TEST)

include $(shell cocotb-config --makefiles)/Makefile.sim
endif