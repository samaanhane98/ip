proc gen_project {dir project_name part} {
    set matched_parts [get_parts $part]

    # Check if the list is not empty
    if {[llength $matched_parts] == 0} {
        puts "Error: '$part' is NOT a valid part or not supported in this Vivado version."
        exit -1
    }

    create_project $project_name [file join $dir] -part $part
    set_property PART $part [current_project]
}

proc add_file {file {type VHDL}} {
    if {![file isfile $file]} {
        error "Source file '$file' does not exist"
    }

    add_files $file

    set file_obj [get_files $file]
    set_property file_type $type $file_obj

    puts "Added source: $file (type: $type)"
}

proc add_modules {path {type VHDL}} {
    set dirs [glob -nocomplain -- $path]

    if {[llength $dirs] == 0} {
        error "No matching directories for '$path'"
    }

    foreach dir $dirs {
        if {![file isdirectory $dir]} {
            continue
        }

        # Match VHDL/Verilog files in each directory.
        set files [glob -nocomplain -directory $dir -types f -- *.vhd *.vhdl *.v]

        foreach file $files {
            add_file $file $type
        }
    }
}

proc add_source {path {type VHDL}} {
    set paths [glob -nocomplain -- $path]

    if {[llength $paths] == 0} {
        error "Source path '$path' does not exist or match any files/directories"
    }

    foreach item $paths {
        if {[file isdirectory $item]} {
            add_modules $item $type
        } elseif {[file isfile $item]} {
            add_file $item $type
        } else {
            puts "Warning: Skipping unsupported path '$item'"
        }
    }
}
