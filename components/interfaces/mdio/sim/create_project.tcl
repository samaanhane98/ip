set project_name "project"
set project_dir  "./work"

create_project $project_name $project_dir -part xc7a35tcpg236-1

# Add design source
add_files ../vhdl_sources/mdio.vhd
add_files ../vhdl_sources/mdio_clock.vhd

# Add testbench
add_files -fileset sim_1 ../vhdl_sim/mdio_tb.vhd

# Set the testbench as the simulation top
set_property top mdio_tb [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

## Save project
#save_project_as $project_name $project_dir