
# -----------------------------------------------------------------------------------------
# Kria FFT - Headless Server Build Script
# -----------------------------------------------------------------------------------------
# Usage (On Server):
#   vivado -mode batch -source server_build.tcl
# -----------------------------------------------------------------------------------------

# 1. Build the Base System & Block Design
#    (This sources your existing script to create the project structure)
puts "--- STARTING HEADLESS BUILD ---"
source build_complete_system.tcl

# 2. Launch Synthesis
puts "--- Launching Synthesis ---"
reset_run synth_1
launch_runs synth_1 -jobs 16
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis Failed. Check runme.log."
    exit 1
}

# 3. Launch Implementation & Bitstream
puts "--- Launching Implementation & Bitstream ---"
launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation Failed. Check runme.log."
    exit 1
}

# 4. Export Hardware (XSA)
puts "--- Exporting Hardware (XSA) ---"
set project_name [current_project]
set project_dir [get_property DIRECTORY [current_project]]
set xsa_name "Kria_FFT_Server_Build.xsa"
set xsa_path "$project_dir/../$xsa_name"

write_hw_platform -fixed -include_bit -force -file $xsa_path

puts "--------------------------------------------------------"
puts "BUILD SUCCESSFUL"
puts "Bitstream and XSA generated: $xsa_name"
puts "You can now download '$xsa_name' to your local machine."
puts "--------------------------------------------------------"
exit 0
