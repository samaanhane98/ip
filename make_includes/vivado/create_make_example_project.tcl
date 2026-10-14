set BUILD_DIR [lindex $argv 0]
set PROJECT_NAME [lindex $argv 1]
set PART [lindex $argv 2]

source scripts/vivado_scripts.tcl

gen_project $BUILD_DIR $PROJECT_NAME $PART

add_source "/home/sam/FPGA/ip/core/axis/vhdl_*" {VHDL 2008}

proc post_create_project {} {
    # Commands to run after generating project
}

post_create_project
