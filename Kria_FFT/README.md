
# Kria FFT - Hardware & Software Implementation
# =============================================

This project implements an FFT-based signal processing system on the Kria KR260 Robotics Starter Kit. It features hardware acceleration for power calculation and extensive data handling between the Processing System (PS) and Programmable Logic (PL).

## Key Features
*   **Sensor Interface**: I2C communication with ADXL345 Accelerometer.
*   **Processing Core**: MicroBlaze Soft Processor for control and data acquisition.
*   **Hardware Acceleration**: Custom Verilog module (`mag_squared.v`) for high-speed Power Calculation ($Real^2 + Imag^2$).
*   **Memory Architecture**: Shared BRAM between MicroBlaze and Zynq MPSoC.
*   **Simulation**: SystemVerilog testbench for verification.

## 1. Directory Structure

| File | Description |
| :--- | :--- |
| `build_kria_fft.tcl` | **Main Build Script**: Creates the Vivado project, Block Design, and configuration. |
| `add_power_block.tcl` | **Hardware Upgrade**: Adds the custom `mag_squared` RTL module to the Block Design. |
| `build_bitstream.tcl` | **Implementation**: Runs Synthesis, Implementation, and Export Hardware (XSA). |
| `mag_squared.v` | **Custom RTL**: Verilog module for calculating signal power magnitude. |
| `adxl345.xdc` | **Constraints**: Physical pin entries for PMOD 1 I2C connections. |
| `sim/tb_system.sv` | **Simulation**: Testbench for verifying system connectivity. |
| `sw/main.c` | **Software**: MicroBlaze C application code. |
| `PC_FFT_Test.c` | **Verification**: Standalone C program to test FFT mathematics on a PC. |

## 2. Hardware Build Instructions (Vivado)

### Step 1: Create the Base System
1.  Open **Vivado 2025.2**.
2.  In the Tcl Console, navigate to this `Kria_FFT` folder.
3.  Run the main build script:
    ```tcl
    source build_kria_fft.tcl
    ```
    *This creates the project, configures the Zynq MPSoC, instantiates the MicroBlaze, and sets up the Shared BRAM with SmartConnect.*

### Step 2: Add Hardware Acceleration
1.  Run the script to add the custom power calculation block:
    ```tcl
    source add_power_block.tcl
    ```
    *This imports `mag_squared.v`, adds it to the Block Design, and connects it to the MicroBlaze via AXI GPIO.*

### Step 3: Synthesis & Implementation
1.  Run the full build flow script:
    ```tcl
    source fix_bitstream.tcl
    ```
    *This script applies the pin constraints (`adxl345.xdc`), runs synthesis and implementation, generates the bitstream, and exports the `Kria_FFT.xsa` hardware platform.*

## 3. Simulation

### Hardware Simulation
To verify the connectivity of the entire system (Zynq + MicroBlaze + Logic):
```tcl
source launch_sim.tcl
```
*This compiles the `sim/tb_system.sv` testbench and launches the Vivado Simulator.*

### Algorithm Verification
To verify the FFT logic independently on your PC (pure C code):
```bash
gcc PC_FFT_Test.c -o fft_test -lm
./fft_test
```

## 4. Software Implementation (Vitis)

The software application (`sw/main.c`) runs on the MicroBlaze processor.

### Application Workflow
1.  **Initialize**: Setup AXI GPIO, IIC, and BRAM Controller.
2.  **Acquire**: Read X, Y, Z acceleration data from the ADXL345 sensor via I2C.
3.  **Process**:
    *   Perform FFT on the Z-axis data.
    *   **Hardware Offload**: Send Real/Imag parts to the custom hardware block via GPIO.
    *   **Read Result**: Read the computed Power Magnitude back from GPIO.
4.  **Store**: Write the final results into the Shared BRAM for the Zynq MPSoC to access.

### Hardware Interface Details
*   **GPIO Output**: Writes packed 32-bit data (Upper 16: Imag, Lower 16: Real).
*   **GPIO Input**: Reads 32-bit Power Magnitude result.
*   **Shared BRAM**: Standard memory mapped interface.

## Requirements
*   **Board**: Kria KR260 Robotics Starter Kit.
*   **Sensor**: ADXL345 Accelerometer connected to **PMOD 1**.
*   **Tools**: Xilinx Vivado & Vitis 2025.2.
