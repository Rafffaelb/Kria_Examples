
# Launch Simulation Script
# ========================

puts "Setting up Simulation..."

# 1. Add Testbench
if { [file exists "./sim/tb_system.sv"] } {
    add_files -fileset sim_1 -norecurse ./sim/tb_system.sv
} else {
    puts "Error: Testbench files not found in ./sim/"
    return
}

# 2. Set Top Module
set_property top tb_system [get_filesets sim_1]
update_compile_order -fileset sim_1

# 3. Launch
puts "Launching Behavioral Simulation..."
launch_simulation

puts "Simulation launched. Please check the Waveform Viewer."
