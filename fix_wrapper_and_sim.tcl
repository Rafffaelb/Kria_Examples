
# Fix Wrapper and Launch Simulation Script
# ========================================

puts "Setting up Simulation..."

# 1. Ensure Wrapper Exists and is added
puts "Generating HDL Wrapper..."
make_wrapper -files [get_files system.bd] -top
add_files -norecurse [glob -nocomplain ./*/*.gen/sources_1/bd/system/hdl/system_wrapper.v]

# 2. Add Testbench
if { [file exists "./sim/tb_system.sv"] } {
    add_files -fileset sim_1 -norecurse ./sim/tb_system.sv
} else {
    puts "Error: Testbench files not found in ./sim/"
    return
}

# 3. Set Top Module
set_property top tb_system [get_filesets sim_1]
update_compile_order -fileset sim_1

# 4. Launch
puts "Launching Behavioral Simulation..."
launch_simulation

puts "Simulation launched. Please check the Waveform Viewer."
