# ------------------------------------------------------------------------
# sim.tcl - export an xsim simulation of top_tb (non-project batch flow)
# Invoked by: make sim-vivado  (runs from build/vivado)
# ------------------------------------------------------------------------

set script_dir [file dirname [info script]]
set root_dir   [file normalize [file join $script_dir .. .. ..]]

source [file join $script_dir board.tcl]

# 1. Create a dummy in-memory project so Vivado can track the files
create_project -in_memory -part $PART

# 2. Read all RTL files AND your Testbench
read_verilog [glob -nocomplain [file join $root_dir rtl *.v]]
read_verilog -sv [glob -nocomplain [file join $root_dir tb *.sv]]

# 3. Set the Top-Level Testbench Module
set_property top top_tb [current_fileset -simset]

# 4. Generate the bash scripts
# This will create a folder at build/vivado/sim_workspace/xsim
export_simulation -simulator xsim -directory ./sim_workspace -force

exit
