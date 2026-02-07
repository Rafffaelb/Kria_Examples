
# Interrupt-Driven I2C (INTC_IIC) Example
# =======================================

This example demonstrates how to implement I2C communication using an Interrupt Controller (INTC).

## Overview
*   **Goal**: Perform non-blocking I2C transactions.
*   **Key Components**: AXI IIC, AXI Interrupt Controller (INTC).
*   **Advantage**: Allows the processor to perform other tasks while waiting for I2C data, improving system efficiency.

## Usage
Refer to the source files for the interrupt handler implementation and I2C callback setup.
