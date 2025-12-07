# Kria_Examples

This repository contains various examples demonstrating hardware-software co-design concepts using AMD/Xilinx Kria SoCs, focusing on communication between processing systems and programmable logic.

## Table of Contents
- [Overview](#overview)
- [Examples](#examples)
  - [I2C](#i2c-example)
  - [INTC_IIC](#intc_iic-example)
  - [INTC_IIC_uB](#intc_iic_ub-example)
  - [SharedBram_Example](#sharedbram_example)
- [Directory Structure](#directory-structure)
- [Getting Started](#getting-started)
- [Prerequisites](#prerequisites)

## Overview

These examples demonstrate key concepts in embedded system design using Xilinx Kria SoCs including:
- I2C communication with sensors
- Interrupt handling
- Hardware-software integration
- Shared memory between processors
- MicroBlaze soft processor usage

Each example includes both Vitis (software) and Vivado (hardware) components.

## Examples

### I2C Example

Demonstrates basic I2C communication with the ADXL345 accelerometer sensor. This example initializes the sensor and continuously reads acceleration values from the X, Y, and Z axes, displaying them via UART.

Key components:
- ADXL345 accelerometer driver
- I2C communication protocol
- Real-time data display

### INTC_IIC Example

Extends the I2C example by incorporating interrupt handling through the Xilinx Interrupt Controller (INTC). Rather than polling the sensor, this example uses interrupts to trigger data readings, which is more efficient for event-driven applications.

Features:
- Interrupt-based I2C communication
- Xilinx Interrupt Controller (INTC) integration
- Exception handling

### INTC_IIC_uB Example

Combines the interrupt-driven I2C communication with shared memory concepts. This example uses a MicroBlaze soft processor to read data from the ADXL345 sensor and store it in a shared AXI BRAM (Block RAM) that can be accessed by other processors.

Architecture:
- MicroBlaze processor for sensor data acquisition
- AXI BRAM for shared memory storage
- I2C communication with ADXL345

### SharedBram_Example

Demonstrates sharing data between processors using AXI Block RAM (BRAM). In this example, one processor writes data to the BRAM while another reads from it, showcasing inter-processor communication mechanisms.

Implementation:
- Dual processor communication
- Shared memory concept using AXI BRAM
- Hardware/software co-design

## Directory Structure

```
├── I2C/
│   ├── Vitis/           # Software sources for I2C example
│   │   ├── ADXL345.cpp  # ADXL345 accelerometer driver implementation
│   │   ├── ADXL345.h    # ADXL345 driver header
│   │   ├── axiWire.hpp  # I2C communication library
│   │   └── example.cpp  # Main application
│   └── Vivado/          # Hardware design sources
│       └── design_1.tcl # TCL script for hardware design
├── INTC_IIC/
│   ├── Vitis/           # Software sources for interrupt-based I2C example
│   │   ├── ADXL345.cpp  # ADXL345 accelerometer driver implementation
│   │   ├── ADXL345.h    # ADXL345 driver header
│   │   ├── axiWire.hpp  # I2C communication library
│   │   └── iic_example.cpp # Main application with interrupt handling
│   └── Vivado/          # Hardware design sources
│       └── design_1.tcl # TCL script for hardware design
├── INTC_IIC_uB/
│   ├── Vitis/
│   │   ├── cortexa53_app/   # Application for Cortex-A53 processor
│   │   │   └── main_cortex.cpp
│   │   └── microblaze_app/  # Application for MicroBlaze processor
│   │       ├── ADXL345.cpp  # ADXL345 accelerometer driver implementation
│   │       ├── ADXL345.h    # ADXL345 driver header
│   │       ├── axiWire.hpp  # I2C communication library
│   │       └── main_ub.cpp  # Main application for MicroBlaze
│   └── Vivado/          # Hardware design sources
│       └── design_1.tcl # TCL script for hardware design
├── SharedBram_Example/
│   ├── Vitis/
│   │   ├── CortexA53-0_app/ # Application for Cortex-A53 processor
│   │   │   └── cortexa53.c  # Reads data from shared BRAM
│   │   └── Microblaze_app/  # Application for MicroBlaze processor
│   │       └── microblaze.c # Writes data to shared BRAM
│   └── Vivado/          # Hardware design sources
│       └── design_1.tcl # TCL script for hardware design
```

## Getting Started

1. Clone this repository
2. Open the desired example's Vivado directory
3. Run the TCL script (`design_1.tcl`) in Vivado to regenerate the hardware design
4. Open the corresponding Vitis directory
5. Create a new Vitis workspace and import the software projects
6. Build and run the applications

## Prerequisites

- Xilinx Vivado Design Suite (2020.1 or later recommended)
- Xilinx Vitis Unified Software Platform
- AMD/Xilinx Kria KV260/KV240 Starter Kit or compatible development board
- USB-UART cable for serial communication
- ADXL345 accelerometer sensor (for I2C examples)