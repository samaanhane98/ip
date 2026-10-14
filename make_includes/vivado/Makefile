# These should be included in other Makefile
VIVADO ?= /tools/Xilinx/2025.1/Vivado/bin/vivado
PROJECT_NAME ?= make_example
PART ?= xc7k325tffg676-2

BUILD_DIR ?= work

all: project 

.PHONE: project
project: $(BUILD_DIR)/$(PROJECT_NAME).xpr
	@echo Generated project $(PROJECT_NAME)

$(BUILD_DIR)/$(PROJECT_NAME).xpr: $(BUILD_DIR) create_$(PROJECT_NAME)_project.tcl
	@$(VIVADO) -mode batch -source create_$(PROJECT_NAME)_project.tcl -tclargs $(BUILD_DIR) $(PROJECT_NAME) $(PART)

$(BUILD_DIR):
	@mkdir $(BUILD_DIR)

.PHONY: clean
clean:
	@test $(BUILD_DIR) && rm -rf $(BUILD_DIR)
	@test .Xil && rm -rf .Xil
	@find . -maxdepth 1 -type f -name 'vivado*.*' -delete

