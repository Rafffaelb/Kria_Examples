
# -----------------------------------------------------------------------------------------
# Kria FFT Complete System Build Script
# -----------------------------------------------------------------------------------------
# Description: 
#   Builds the entire Kria KR260 project from scratch, including the Zynq MPSoC, 
#   MicroBlaze, Shared BRAM, and the Custom Power Calculation Hardware Block.
#   Configures "Global Synthesis" to avoid Out-of-Context (OOC) errors.
#
# Usage:
#   1. Open Vivado 2025.2.
#   2. In Tcl Console: cd c:/Users/rafam/Documents/TU_Dresden/Kria_Examples/Kria_FFT
#   3. In Tcl Console: source build_complete_system.tcl
# -----------------------------------------------------------------------------------------

set project_name "Kria_FFT"
set project_dir "./$project_name"
set board_part "xilinx.com:kr260_som:part0:1.1"
set device_part "xck26-sfvc784-2LV-c"

# =========================================================================================
# PART 1: BASE SYSTEM CREATION
# =========================================================================================

# 1. Clean Up and Create Project
# ------------------------------
puts "--- Cleaning up old project files ---"
file delete -force $project_dir
create_project -force $project_name $project_dir -part $device_part
set_property board_part $board_part [current_project]

puts "--- Creating Block Design 'system' ---"
create_bd_design "system"

# 2. Add IPs
# ----------
puts "--- Adding Base IPs ---"

# Zynq UltraScale+
set zynq [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0]
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1"} $zynq
# Enable FPD Master (Full Power Domain)
set_property CONFIG.PSU__USE__M_AXI_GP0 {1} $zynq
set_property CONFIG.PSU__USE__M_AXI_GP1 {0} $zynq

# MicroBlaze
set mb [create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0]
# Use automation for strictly MB internals (LMB, MDM, RST), but we will handle AXI ourselves
# We let it create 'axi_periph' (Enabled) then we will delete it to replace with SmartConnect
apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { \
    local_mem "64KB" \
    ecc "None" \
    cache "None" \
    debug_module "Debug Only" \
    axi_periph "Enabled" \
    axi_intc "1" \
    clk "/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)" \
} $mb

# Delete the auto-generated legacy AXI Interconnect (if it exists) to prevent OOC errors
set old_ic [get_bd_cells -quiet microblaze_0_axi_periph]
if { $old_ic != "" } {
    puts "--- Replacing Legacy AXI Interconnect with SmartConnect ---"
    delete_bd_objs $old_ic
}

# Peripherals
set iic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0]
set mb_bram_ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl mb_bram_ctrl]
set ps_bram_ctrl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl ps_bram_ctrl]
set shared_bram [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen shared_bram]

# Configure BRAM Controllers
set_property CONFIG.SINGLE_PORT_BRAM {1} $mb_bram_ctrl
set_property CONFIG.SINGLE_PORT_BRAM {1} $ps_bram_ctrl

# Configure Shared BRAM (True Dual Port)
set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Use_RSTB_Pin {true} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Write_Rate {50} \
    CONFIG.Port_B_Enable_Rate {100} \
] $shared_bram

# 3. Add SmartConnects
# --------------------
puts "--- Adding SmartConnects ---"
# SmartConnect for MicroBlaze Masters
# Note: We set NUM_MI to 5 initially to accommodate the Custom Block later
set smc_mb [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smc_mb]
set_property CONFIG.NUM_MI {5} $smc_mb
set_property CONFIG.NUM_SI {1} $smc_mb

# SmartConnect for Zynq Master (Connecting to PS BRAM Ctrl)
set smc_ps [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smc_ps]
set_property CONFIG.NUM_MI {1} $smc_ps
set_property CONFIG.NUM_SI {1} $smc_ps

# 4. Connectivity (Base)
# ----------------------
puts "--- Wiring Base System ---"

# Helper Variables
set rst_blk [get_bd_cells *rst*]
set intc [get_bd_cells *axi_intc*]
set clk_src [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
set rst_interconnect [get_bd_pins $rst_blk/interconnect_aresetn]
set rst_peripheral [get_bd_pins $rst_blk/peripheral_aresetn]

# -- Clocks --
connect_bd_net $clk_src [get_bd_pins smc_mb/aclk]
connect_bd_net $clk_src [get_bd_pins smc_ps/aclk]
connect_bd_net $clk_src [get_bd_pins axi_iic_0/s_axi_aclk]
connect_bd_net $clk_src [get_bd_pins mb_bram_ctrl/s_axi_aclk]
connect_bd_net $clk_src [get_bd_pins ps_bram_ctrl/s_axi_aclk]

# -- Resets --
connect_bd_net $rst_interconnect [get_bd_pins smc_mb/aresetn]
connect_bd_net $rst_interconnect [get_bd_pins smc_ps/aresetn]
connect_bd_net $rst_peripheral [get_bd_pins axi_iic_0/s_axi_aresetn]
connect_bd_net $rst_peripheral [get_bd_pins mb_bram_ctrl/s_axi_aresetn]
connect_bd_net $rst_peripheral [get_bd_pins ps_bram_ctrl/s_axi_aresetn]

# -- Data Interfaces (MicroBlaze) --
# MB -> SMC
connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins smc_mb/S00_AXI]
# SMC -> IIC (M00)
connect_bd_intf_net [get_bd_intf_pins smc_mb/M00_AXI] [get_bd_intf_pins axi_iic_0/S_AXI]
# SMC -> MB BRAM (M01)
connect_bd_intf_net [get_bd_intf_pins smc_mb/M01_AXI] [get_bd_intf_pins mb_bram_ctrl/S_AXI]
# SMC -> INTC (M02)
if { $intc != "" } {
    connect_bd_intf_net [get_bd_intf_pins smc_mb/M02_AXI] [get_bd_intf_pins $intc/s_axi]
    # Re-verify Interrupt connection
    connect_bd_intf_net [get_bd_intf_pins $intc/interrupt] [get_bd_intf_pins microblaze_0/INTERRUPT]
}

# -- Data Interfaces (Zynq) --
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smc_ps/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smc_ps/M00_AXI] [get_bd_intf_pins ps_bram_ctrl/S_AXI]

# -- BRAM --
connect_bd_intf_net [get_bd_intf_pins mb_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins shared_bram/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins ps_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins shared_bram/BRAM_PORTB]

# 5. Finalize Base
# ----------------
make_bd_intf_pins_external [get_bd_intf_pins axi_iic_0/IIC]
set_property name "adxl345_iic" [get_bd_intf_ports IIC_0]

# =========================================================================================
# PART 2: CUSTOM POWER BLOCK INTEGRATION
# =========================================================================================

puts "--- Adding Custom Power Calculation Block ---"

# 1. Add Source File
set rtl_file "./mag_squared.v"
if { [file exists $rtl_file] } {
    add_files -norecurse $rtl_file
    set_property file_type "Verilog" [get_files $rtl_file]
} else {
    puts "Error: RTL file not found! Please ensure 'mag_squared.v' is in the current directory."
    return
}

# 2. Add RTL Module Reference
create_bd_cell -type module -reference mag_squared power_calc_0

# 3. Add AXI GPIOs
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

# 4. Connect GPIO Ports to Module Ports
connect_bd_net [get_bd_pins axi_gpio_out/gpio_io_o] [get_bd_pins power_calc_0/data_in]
connect_bd_net [get_bd_pins power_calc_0/power_out] [get_bd_pins axi_gpio_in/gpio_io_i]

# 5. Connect AXI Interface to SmartConnect (M03 & M04)
# We already set NUM_MI to 5 in Part 1
connect_bd_intf_net [get_bd_intf_pins smc_mb/M03_AXI] [get_bd_intf_pins axi_gpio_out/S_AXI]
connect_bd_intf_net [get_bd_intf_pins smc_mb/M04_AXI] [get_bd_intf_pins axi_gpio_in/S_AXI]

# 6. Connect Clocks & Resets
connect_bd_net $clk_src [get_bd_pins axi_gpio_out/s_axi_aclk]
connect_bd_net $clk_src [get_bd_pins axi_gpio_in/s_axi_aclk]
connect_bd_net $rst_peripheral [get_bd_pins axi_gpio_out/s_axi_aresetn]
connect_bd_net $rst_peripheral [get_bd_pins axi_gpio_in/s_axi_aresetn]

# =========================================================================================
# PART 3: FINALIZATION
# =========================================================================================

puts "--- Validating and Saving Design ---"
assign_bd_address
validate_bd_design
save_bd_design
close_bd_design [current_bd_design]

# Set Global Synthesis (CRITICAL FIX)
puts "--- Configuring Global Synthesis to bypass OOC errors ---"
set_property synth_checkpoint_mode None [get_files system.bd]

puts "--------------------------------------------------------"
puts "SUCCESS: Project 'Kria_FFT' created with Custom Power Block."
puts "You can now run 'source fix_bitstream.tcl' to implement."
puts "--------------------------------------------------------"
