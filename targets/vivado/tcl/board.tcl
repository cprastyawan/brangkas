# ------------------------------------------------------------------------
# board.tcl - shared part settings for the Vivado non-project batch flow.
# Sourced by synth.tcl and sim.tcl so the target device is only defined
# in one place.
# ------------------------------------------------------------------------

# Zybo Z7-10 (default board variant). If you have a Zybo Z7-20 instead,
# change this to xc7z020-1clg400c. Note zybo_z7.xdc has extra I/O
# (led5_r/g/b, fan_fb_pu, etc.) that only exist on the Z7-20 - leave those
# commented out unless your board and design actually use them.
set PART "xc7z010clg400-1"
