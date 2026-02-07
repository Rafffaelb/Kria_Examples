
# Add Custom Power Block to Block Design
# ======================================

puts "Adding Custom Power Calculation Block..."

# 1. Add Source File
set rtl_file "./mag_squared.v"
if { [file exists $rtl_file] } {
    add_files -norecurse $rtl_file
    set_property file_type "Verilog" [get_files $rtl_file]
} else {
    puts "Error: RTL file not found!"
    return
}

# 2. Open Layout
set existing_bd [get_files *.bd]
if { $existing_bd != "" } {
    puts "Found existing BD: $existing_bd"
    open_bd_design $existing_bd
} else {
    puts "No BD found in project. Adding from source..."
    set bd_path "c:/Users/rafam/Documents/TU_Dresden/Kria_FFT/Kria_FFT/Kria_FFT.srcs/sources_1/bd/system/system.bd"
    add_files -norecurse $bd_path
    open_bd_design $bd_path
}

# 3. Add RTL Module Reference (The Block)
create_bd_cell -type module -reference mag_squared power_calc_0

# 4. Add AXI GPIOs for Interface
# GPIO OUT: 32-bit (Data In to Module)
set gpio_out [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_out]
set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {32} \
] $gpio_out

# GPIO IN: 32-bit (Power Out from Module)
set gpio_in [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_in]
set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_GPIO_WIDTH {32} \
] $gpio_in

# 5. Connect GPIO Ports to Module Ports
# GPIO Out -> Module In (data_in)
connect_bd_net [get_bd_pins axi_gpio_out/gpio_io_o] [get_bd_pins power_calc_0/data_in]

# Module Out -> GPIO In (gpio_io_i)
connect_bd_net [get_bd_pins power_calc_0/power_out] [get_bd_pins axi_gpio_in/gpio_io_i]

# 6. Connect AXI Interface via SmartConnect
# Increase Master count on SmartConnect (was 3, needs 5 now)
set smc_mb [get_bd_cells smc_mb]
set_property CONFIG.NUM_MI {5} $smc_mb

# Connect AXI
connect_bd_intf_net [get_bd_intf_pins smc_mb/M03_AXI] [get_bd_intf_pins axi_gpio_out/S_AXI]
connect_bd_intf_net [get_bd_intf_pins smc_mb/M04_AXI] [get_bd_intf_pins axi_gpio_in/S_AXI]

# 7. Connect Clocks & Resets
set clk [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
set rst [get_bd_pins rst_ps8_0_99M/peripheral_aresetn]

connect_bd_net $clk [get_bd_pins axi_gpio_out/s_axi_aclk]
connect_bd_net $clk [get_bd_pins axi_gpio_in/s_axi_aclk]
connect_bd_net $rst [get_bd_pins axi_gpio_out/s_axi_aresetn]
connect_bd_net $rst [get_bd_pins axi_gpio_in/s_axi_aresetn]

# 8. Address Assignment
assign_bd_address

# 9. Save
validate_bd_design
save_bd_design

puts "Custom Block Added Successfully."
