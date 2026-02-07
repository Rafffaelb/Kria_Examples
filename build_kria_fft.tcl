
# -----------------------------------------------------------------------------------------
# Kria FFT Robust Build Script
# -----------------------------------------------------------------------------------------
# Description: 
#   Rebuilds the Kria KR260 project from scratch using SmartConnects.
#   Configures "Global Synthesis" to avoid Out-of-Context (OOC) errors (bd_f000).
#   Does NOT auto-launch simulation/synthesis to allow user inspection.
#
# Usage:
#   1. Open Vivado 2025.2.
#   2. In Tcl Console: cd c:/Users/rafam/Documents/TU_Dresden/Kria_FFT
#   3. In Tcl Console: source build_kria_fft.tcl
# -----------------------------------------------------------------------------------------

set project_name "Kria_FFT"
set project_dir "./$project_name"
set board_part "xilinx.com:kr260_som:part0:1.1"
set device_part "xck26-sfvc784-2LV-c"

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
puts "--- Adding IPs ---"

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
# SmartConnect for MicroBlaze Masters (Connecting to IIC, BRAM, INTC)
set smc_mb [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smc_mb]
set_property CONFIG.NUM_MI {3} $smc_mb
set_property CONFIG.NUM_SI {1} $smc_mb

# SmartConnect for Zynq Master (Connecting to PS BRAM Ctrl)
set smc_ps [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smc_ps]
set_property CONFIG.NUM_MI {1} $smc_ps
set_property CONFIG.NUM_SI {1} $smc_ps

# 4. Connectivity
# ---------------
puts "--- Wiring System ---"

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
# INTC clock is usually connected by automation, skipping explicit connect to avoid error

# -- Resets --
connect_bd_net $rst_interconnect [get_bd_pins smc_mb/aresetn]
connect_bd_net $rst_interconnect [get_bd_pins smc_ps/aresetn]
connect_bd_net $rst_peripheral [get_bd_pins axi_iic_0/s_axi_aresetn]
connect_bd_net $rst_peripheral [get_bd_pins mb_bram_ctrl/s_axi_aresetn]
connect_bd_net $rst_peripheral [get_bd_pins ps_bram_ctrl/s_axi_aresetn]
# INTC reset is usually connected by automation, skipping explicit connect

# -- Data Interfaces (MicroBlaze) --
# MB -> SMC
connect_bd_intf_net [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins smc_mb/S00_AXI]
# SMC -> IIC
connect_bd_intf_net [get_bd_intf_pins smc_mb/M00_AXI] [get_bd_intf_pins axi_iic_0/S_AXI]
# SMC -> MB BRAM
connect_bd_intf_net [get_bd_intf_pins smc_mb/M01_AXI] [get_bd_intf_pins mb_bram_ctrl/S_AXI]
# SMC -> INTC (if present)
if { $intc != "" } {
    connect_bd_intf_net [get_bd_intf_pins smc_mb/M02_AXI] [get_bd_intf_pins $intc/s_axi]
    # Re-verify Interrupt connection just in case automation missed it
    connect_bd_intf_net [get_bd_intf_pins $intc/interrupt] [get_bd_intf_pins microblaze_0/INTERRUPT]
}

# -- Data Interfaces (Zynq) --
# Zynq FPD -> SMC -> PS BRAM
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smc_ps/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smc_ps/M00_AXI] [get_bd_intf_pins ps_bram_ctrl/S_AXI]

# -- BRAM --
connect_bd_intf_net [get_bd_intf_pins mb_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins shared_bram/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins ps_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins shared_bram/BRAM_PORTB]

# 5. Finalize
# -----------
puts "--- Finalizing Design ---"
make_bd_intf_pins_external [get_bd_intf_pins axi_iic_0/IIC]
set_property name "adxl345_iic" [get_bd_intf_ports IIC_0]
assign_bd_address
save_bd_design
close_bd_design [current_bd_design]

# 6. Set Global Synthesis (CRITICAL FIX)
# --------------------------------------
# This forces Vivado to synthesize the BD as a whole, bypassing the generation
# of separate OOC runs for sub-modules causing the path/file errors.
puts "--- Configuring Global Synthesis to bypass OOC errors ---"
set_property synth_checkpoint_mode None [get_files system.bd]

puts "--------------------------------------------------------"
puts "SUCCESS: Project 'Kria_FFT' created."
puts "You can now open the block design 'system' to verify."
puts "--------------------------------------------------------"
