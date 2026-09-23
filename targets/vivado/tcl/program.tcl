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

# The Zynq-7000 JTAG chain always shows up as (at least) two hw_devices:
# arm_dap_0 (the ARM debug port - not programmable with a bitstream) and
# xc7z010_1 / xc7z020_1 (the PL device we actually want). Filter to the
# xc7z* one so arm_dap_0 never gets picked by [lindex ... 0].
set hw_device [lindex [get_hw_devices xc7z*] 0]
if {$hw_device eq ""} {
    puts "ERROR: no Zynq PL device found on the JTAG chain. Check that the Zybo Z7 is"
    puts "powered on, connected via USB, and that JP5 is set to JTAG. Devices seen:"
    puts "  [get_hw_devices]"
    close_hw_target
    close_hw_manager
    exit 1
}

current_hw_device $hw_device
refresh_hw_device -update_hw_probes false $hw_device
set_property PROGRAM.FILE $bitstream $hw_device

puts "Programming $hw_device with $bitstream ..."
program_hw_devices $hw_device

puts "Programming complete."
close_hw_target
close_hw_manager
exit