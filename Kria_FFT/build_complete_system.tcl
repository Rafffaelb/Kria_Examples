
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
# PART 2: HARDWARE ACCELERATION (FFT + DMA + CUSTOM BLOCK)
# =========================================================================================

puts "--- Adding Hardware Acceleration Cores ---"

# 1. Add Source File (Custom Power Block - Streaming Version)
set rtl_file "./mag_squared.v"
if { [file exists $rtl_file] } {
    add_files -norecurse $rtl_file
    set_property file_type "Verilog" [get_files $rtl_file]
} else {
    puts "Error: RTL file not found!"
    return
}
create_bd_cell -type module -reference mag_squared power_calc_0

# 2. Add Xilinx FFT IP (xfft)
# Configure for Pipelined Streaming I/O, Output Order Natural
set xfft [create_bd_cell -type ip -vlnv xilinx.com:ip:xfft xfft_0]
set_property -dict [list \
    CONFIG.transform_length {1024} \
    CONFIG.target_clock_frequency {100} \
    CONFIG.implementation_options {Pipelined_Streaming_IO} \
    CONFIG.data_format {Fixed_Point} \
    CONFIG.input_width {16} \
    CONFIG.phase_factor_width {16} \
    CONFIG.scaling_options {Unscaled} \
    CONFIG.rounding_modes {Truncation} \
    CONFIG.output_ordering {Natural_Order} \
    CONFIG.throttle_scheme {NonRealTime} \
] $xfft

# 3. Add AXI DMA
# Simple Mode (Scatter Gather Disabled), Width matching our data (32-bit)
set dma [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_dma_0]
set_property -dict [list \
    CONFIG.c_include_sg {0} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_addr_width {32} \
] $dma

# 4. Connectivity: Memory -> DMA -> FFT -> PowerCalc -> DMA -> Memory
# -------------------------------------------------------------------

# Connect Clocks & Resets (Global System Clock)
connect_bd_net $clk_src [get_bd_pins xfft_0/aclk]
connect_bd_net $clk_src [get_bd_pins axi_dma_0/s_axi_lite_aclk]
connect_bd_net $clk_src [get_bd_pins axi_dma_0/m_axi_mm2s_aclk]
connect_bd_net $clk_src [get_bd_pins axi_dma_0/m_axi_s2mm_aclk]
connect_bd_net $clk_src [get_bd_pins power_calc_0/aclk]

# Shared Reset
connect_bd_net $rst_peripheral [get_bd_pins axi_dma_0/axi_resetn]
connect_bd_net $rst_peripheral [get_bd_pins power_calc_0/aresetn]
# FFT uses aresetn (Active Low)
connect_bd_net $rst_peripheral [get_bd_pins xfft_0/aresetn]

# DATA PATH (Streaming)
# ---------------------
# We use explicit pin-level connections to avoid interface compatibility issues

# 1. DMA MM2S (Read from Ram) -> FFT Slave
# TDATA
connect_bd_net [get_bd_pins axi_dma_0/m_axis_mm2s_tdata] [get_bd_pins xfft_0/s_axis_data_tdata]
# TVALID
connect_bd_net [get_bd_pins axi_dma_0/m_axis_mm2s_tvalid] [get_bd_pins xfft_0/s_axis_data_tvalid]
# TLAST
connect_bd_net [get_bd_pins axi_dma_0/m_axis_mm2s_tlast] [get_bd_pins xfft_0/s_axis_data_tlast]
# TREADY
connect_bd_net [get_bd_pins xfft_0/s_axis_data_tready] [get_bd_pins axi_dma_0/m_axis_mm2s_tready]
# Note: DMA provides TKEEP, but FFT doesn't use it. We ignore it here.

# 2. FFT Master -> PowerCalc Slave
# TDATA
connect_bd_net [get_bd_pins xfft_0/m_axis_data_tdata] [get_bd_pins power_calc_0/s_axis_tdata]
# TVALID
connect_bd_net [get_bd_pins xfft_0/m_axis_data_tvalid] [get_bd_pins power_calc_0/s_axis_tvalid]
# TLAST
connect_bd_net [get_bd_pins xfft_0/m_axis_data_tlast] [get_bd_pins power_calc_0/s_axis_tlast]
# TREADY
connect_bd_net [get_bd_pins power_calc_0/s_axis_tready] [get_bd_pins xfft_0/m_axis_data_tready]

# Handle TKEEP for PowerCalc Input
# FFT doesn't output TKEEP, but PowerCalc needs an input to pass through to DMA.
# We tie it to all 1s (0xF for 32-bit/4-byte) to indicate all bytes valid.
set const_keep [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_keep]
set_property CONFIG.CONST_VAL {15} $const_keep
set_property CONFIG.CONST_WIDTH {4} $const_keep
connect_bd_net [get_bd_pins const_keep/dout] [get_bd_pins power_calc_0/s_axis_tkeep]

# 3. PowerCalc Master -> DMA S2MM (Write to Ram)
# TDATA
connect_bd_net [get_bd_pins power_calc_0/m_axis_tdata] [get_bd_pins axi_dma_0/s_axis_s2mm_tdata]
# TKEEP (Passed through from constant)
connect_bd_net [get_bd_pins power_calc_0/m_axis_tkeep] [get_bd_pins axi_dma_0/s_axis_s2mm_tkeep]
# TVALID
connect_bd_net [get_bd_pins power_calc_0/m_axis_tvalid] [get_bd_pins axi_dma_0/s_axis_s2mm_tvalid]
# TLAST
connect_bd_net [get_bd_pins power_calc_0/m_axis_tlast] [get_bd_pins axi_dma_0/s_axis_s2mm_tlast]
# TREADY
connect_bd_net [get_bd_pins axi_dma_0/s_axis_s2mm_tready] [get_bd_pins power_calc_0/m_axis_tready]

# 4. FFT Configuration (Tie Low/Fixed)
# We need to drive s_axis_config_tvalid and tdata to defaults (0)
set const_config [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_config]
set_property CONFIG.CONST_VAL {0} $const_config
set_property CONFIG.CONST_WIDTH {1} $const_config

# Connect val ('0') to tvalid.
# Note: Some FFT configs require tdata to be driven too even if 0.
# Let's verify width. If width is > 1 on config_tdata, we might need a wider constant.
# For standard Unscaled, Natural order, config path might be minimal.
connect_bd_net [get_bd_pins const_config/dout] [get_bd_pins xfft_0/s_axis_config_tvalid]

# Drive tdata with 0s as well just to be safe (prevent X propagation)
# We create a 16-bit zero constant (safe upper bound for config, usually 8-24 bits)
set const_zeros [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_zeros]
set_property CONFIG.CONST_VAL {0} $const_zeros
set_property CONFIG.CONST_WIDTH {16} $const_zeros
connect_bd_net [get_bd_pins const_zeros/dout] [get_bd_pins xfft_0/s_axis_config_tdata]

# CONTROL PATH (AXI Lite)
# -----------------------

# Reconfigure smc_mb (for MB -> Peripherals)
# MB needs to see: IIC, BRAM_CTRL, INTC, DMA_LITE. Total 4.
set_property CONFIG.NUM_MI {4} $smc_mb
connect_bd_intf_net [get_bd_intf_pins smc_mb/M03_AXI] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]

# Reconfigure smc_ps (for Masters -> Ram)
# Zynq, DMA_MM2S, DMA_S2MM all need to access Shared BRAM.
# Currently smc_ps is: Zynq -> BRAM.
# We set NUM_SI to 3: S00(Zynq), S01(DMA_MM2S), S02(DMA_S2MM)
set_property CONFIG.NUM_SI {3} $smc_ps

# Connect DMA Masters to SmartConnect Slaves
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins smc_ps/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins smc_ps/S02_AXI]

# Clocks/Resets for new SMC ports
# Explicitly connect clock to all SI slots on smc_ps to avoid validation warnings
connect_bd_net $clk_src [get_bd_pins smc_ps/aclk]
# (Often aclk1, s01_aclk etc exist depending on config, but SmartConnect usually collapses to one aclk if not using separate clocks)
# Let's try connecting to specific pins if they exist, or just 'aclk' which usually drives all.


puts "Hardware Acceleration Blocks (FFT + DMA) Added."

# =========================================================================================
# PART 3: CONSTRAINTS
# =========================================================================================

puts "--- Adding Constraints ---"
set xdc_file "./adxl345.xdc"
if { [file exists $xdc_file] } {
    add_files -fileset constrs_1 -norecurse $xdc_file
    set_property file_type "XDC" [get_files $xdc_file]
    puts "Constraints file '$xdc_file' added."
} else {
    puts "WARNING: Constraints file '$xdc_file' not found! Implementation may fail."
}

# =========================================================================================
# PART 4: FINALIZATION
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
