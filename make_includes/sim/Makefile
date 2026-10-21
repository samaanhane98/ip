# Find index in list
_idx  = $(if $2,$(if $(filter $1,$(firstword $2)),$(words $3),$(call _idx,$1,$(wordlist 2,$(words $2),$2),$3 x)))
pos = $(call _idx,$1,$2,x)

# Makefile
THIS := $(lastword $(MAKEFILE_LIST))

ifeq ($(T),)

# Export Makefile variables they are usable in the sub-process calls
export MODULE
export MODULE_TOP
export MODULE_TEST
export VHDL_SOURCES
export PYTHONPATH

.PHONY: all clean $(MODULE)

all: $(MODULE)

# TODO: supress log here?
$(MODULE):
	$(MAKE) -f $(THIS) T=$@

%.sim:
	$(MAKE) -f $(THIS) T=$*

%.gui:
	$(MAKE) -f $(THIS) GUI=1 T=$*

clean:
	rm -rf work results*.xml __pycache__ *.wlf transcript modelsim.ini

else

SIM=questa-compat
WAVES=0
COMPILE_ARGS += -2008 +acc
TOPLEVEL_LANG ?= vhdl

SIM_BUILD = work/work_$(T)

INDEX := $(call pos,$(T),$(MODULE))

COCOTB_TOPLEVEL     = $(word $(INDEX),$(MODULE_TOP))
COCOTB_TEST_MODULES = $(word $(INDEX),$(MODULE_TEST))

include $(shell cocotb-config --makefiles)/Makefile.sim
endif