# ------------------------------------------------------------------------
# synth.tcl - synthesize the design (non-project batch flow)
# Invoked by: make synth-vivado  (runs from build/vivado)
# Paths below are resolved relative to this script's own location, not
# the invocation directory, so this also works if you source it directly
# from the repo root.
# ------------------------------------------------------------------------

set script_dir [file dirname [info script]]
set root_dir   [file normalize [file join $script_dir .. .. ..]]

source [file join $script_dir board.tcl]

# 1. Read Verilog from the RTL directory
set verilog_files [glob -nocomplain [file join $root_dir rtl *.v]]
if {[llength $verilog_files] == 0} {
    puts "ERROR: no Verilog sources found under $root_dir/rtl"
    exit 1
}
puts "Reading Verilog files: $verilog_files"
read_verilog $verilog_files

# 2. Read constraints
read_xdc [file join $root_dir targets vivado xdc zybo_z7.xdc]

# 3. Synthesize
synth_design -top top -part $PART

# 4. Output files (these drop directly into build/vivado/, the cwd this
# is launched from)
write_checkpoint -force post_synth.dcp
report_utilization -file utilization.txt
report_timing_summary -file timing.txt

puts "Synthesis complete -> post_synth.dcp"
exit
