# ------------------------------------------------------------------------
# program.tcl - program the Zybo Z7 over JTAG with the bitstream produced
# by impl.tcl.
# Invoked by: make program-vivado  (runs from build/vivado, right after
# impl-vivado, and expects top.bit to already be sitting there)
#
# Prerequisites: Zybo Z7 powered on, connected via the micro-USB JTAG/UART
# port, and JP5 set to JTAG boot mode.
# ------------------------------------------------------------------------

set bitstream "top.bit"
if {![file exists $bitstream]} {
    puts "ERROR: $bitstream not found in [pwd] - run implementation first (make impl-vivado)."
    exit 1
}

open_hw_manager
# If your hw_server runs on a different machine, add: -url <host>:3121
connect_hw_server
open_hw_target

set hw_device [lindex [get_hw_devices] 0]
if {$hw_device eq ""} {
    puts "ERROR: no hardware device found. Check that the Zybo Z7 is powered on,"
    puts "connected via USB, and that JP5 is set to JTAG."
    close_hw_target
    close_hw_manager
    exit 1
}
# If more than one device shows up on the JTAG chain, replace the line
# above with something like: set hw_device [get_hw_devices xc7z010_1]
# (or xc7z020_1 on a Zybo Z7-20) to pick the right one explicitly.

current_hw_device $hw_device
refresh_hw_device -update_hw_probes false $hw_device
set_property PROGRAM.FILE $bitstream $hw_device

puts "Programming $hw_device with $bitstream ..."
program_hw_devices $hw_device

puts "Programming complete."
close_hw_target
close_hw_manager
exit
