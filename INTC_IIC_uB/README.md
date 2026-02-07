
# MicroBlaze Interrupt-Driven I2C (INTC_IIC_uB)
# =============================================

This project implements the Interrupt-Driven I2C design specifically for the **MicroBlaze** soft processor.

## Overview
*   **Target**: MicroBlaze (Soft Core).
*   **Goal**: control I2C peripherals via interrupts within the MicroBlaze subsystem.
*   **Mechanism**: MicroBlaze connects to an AXI INTC, which aggregates interrupts from the AXI IIC and other peripherals.

## Usage
Load the bitstream containing the MicroBlaze design and run the provided software application.
