
# Fix Constraints and Rebuild Bitstream
# =====================================

puts "Adding Constraints and Rerunning Bitstream..."

# 1. Add XDC File
set xdc_file "./adxl345.xdc"
if { [file exists $xdc_file] } {
    add_files -fileset constrs_1 -norecurse $xdc_file
} else {
    puts "Error: XDC file not found!"
    return
}

# 2. Reset Implementation to force re-use of new constraints
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# 3. Check & Export
if {[get_property PROGRESS [get_runs impl_1]] == "100%"} {
    puts "Bitstream Generated."
    
    set project_name [current_project]
    set project_dir [get_property DIRECTORY [current_project]]
    set xsa_path "$project_dir/${project_name}.xsa"

    write_hw_platform -fixed -include_bit -force -file $xsa_path
    puts "Hardware exported to: $xsa_path"
} else {
    puts "ERROR: Bitstream generation failed again. Check messages."
}
