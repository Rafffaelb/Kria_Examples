
# Kria KR260 Projects and Examples
# ================================

This repository contains a collection of hardware and software examples for the **Xilinx Kria KR260 Robotics Starter Kit**. Each project demonstrates specific capabilities of the Zynq UltraScale+ MPSoC and MicroBlaze soft processors.

## Projects Overview

| Project Identifier | Description |
| :--- | :--- |
| **[Kria_FFT](./Kria_FFT)** | A full hardware/software Fast Fourier Transform (FFT) implementation using MicroBlaze, AXI GPIO, Custom Verilog Logic, and Shared BRAM. **(Featured)** |
| **[I2C](./I2C)** | Basic I2C communication example. Demonstrates how to interface sensors or peripherals using the PS or PL I2C controllers. |
| **[INTC_IIC](./INTC_IIC)** | Interrupt-driven I2C implementation. Shows how to handle I2C events efficiently using the Interrupt Controller (INTC). |
| **[INTC_IIC_uB](./INTC_IIC_uB)** | MicroBlaze implementation of the Interrupt-driven I2C design. Focuses on soft-processor control handling. |
| **[SharedBram_Example](./SharedBram_Example)** | Examples of data exchange between the Processing System (PS) and Programmable Logic (PL) or MicroBlaze using Shared Block RAM (BRAM).|

## Getting Started

1.  Clone this repository:
    ```bash
    git clone https://github.com/Rafffaelb/Kria_Examples.git
    ```
2.  Navigate to the specific example folder you are interested in.
3.  Follow the `README.md` inside that folder for build and run instructions.

## Requirements
*   **Hardware**: Kria KR260 Robotics Starter Kit
*   **Software**: Vivado & Vitis 2025.2 (or compatible)
