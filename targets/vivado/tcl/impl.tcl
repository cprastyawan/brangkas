# ------------------------------------------------------------------------
# impl.tcl - implement the design and generate the bitstream
# Invoked by: make impl-vivado  (runs from build/vivado, right after
# synth-vivado, and expects post_synth.dcp to already be sitting there)
# ------------------------------------------------------------------------

# 1. Open the synthesized checkpoint
if {![file exists post_synth.dcp]} {
    puts "ERROR: post_synth.dcp not found in [pwd] - run synthesis first (make synth-vivado)."
    exit 1
}
open_checkpoint post_synth.dcp

# 2. Logic Optimization
# Simplifies logic, sweeps away unused cells, and optimizes the netlist
opt_design

# 3. Placement
# Physically maps your logic gates to specific slices on the Zybo-Z7
place_design

# 4. Physical Optimization (Highly Recommended)
# Optimizes routing and logic placement to fix minor timing violations
phys_opt_design

# 5. Routing
# Connects all the physical wires between the placed logic slices
route_design

# 6. Save a Post-Route Checkpoint
# Extremely useful if you ever need to open the Vivado GUI to debug timing
write_checkpoint -force post_route.dcp

# 7. Design Rule Check
# Catches routing/unconnected-pin problems before spending time on bitgen
report_drc -file impl_drc.txt

# 8. Generate Implementation Reports
report_timing_summary -file impl_timing_summary.txt
report_utilization -file impl_utilization.txt

# 9. Generate the Bitstream!
# Note: The file name usually matches your top-level module name
write_bitstream -force top.bit

puts "Implementation complete -> [pwd]/top.bit"
exit
