
# Build Bitstream Script
# ======================
# This script automates the full hardware build process:
# Synthesis -> Implementation -> Bitstream Generation -> Hardware Export

puts "Starting Full Hardware Build..."

# 1. Synthesis
# ------------
puts "--- Launching Synthesis ---"
# Reset run to ensure a clean start
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Check Status
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed. Check the 'Messages' tab or run logs."
    return
}
puts "Synthesis Complete."

# 2. Implementation & Bitstream
# -----------------------------
puts "--- Launching Implementation & Bitstream Generation ---"
# 'to_step write_bitstream' runs opt_design, place_design, route_design, and write_bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Check Status
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation or Bitstream Generation failed."
    return
}
puts "Bitstream Generated Successfully."

# 3. Export Hardware (XSA)
# ------------------------
puts "--- Exporting Hardware (XSA) ---"
set project_name [current_project]
set project_dir [get_property DIRECTORY [current_project]]
# Standard naming convention: <project_name>_wrapper.xsa or similar. 
# We'll use the project name.
set xsa_path "$project_dir/${project_name}.xsa"

# -fixed: For embedded systems (Zynq)
# -include_bit: Crucial for Vitis to program the FPGA
# -force: Overwrite existing
write_hw_platform -fixed -include_bit -force -file $xsa_path

puts "-----------------------------------------------------------"
puts "BUILD SUCCESSFUL"
puts "Exported Hardware Location: $xsa_path"
puts "You can now proceed to Vitis."
puts "-----------------------------------------------------------"
