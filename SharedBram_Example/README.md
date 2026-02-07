
# Shared BRAM Example
# ===================

This example demonstrates data exchange between different system components using Shared Block RAM (BRAM).

## Overview
*   **Architecture**: Double Address Model (True Dual Port RAM).
*   **Use Case**: Transferring large data buffers between the Zynq Processing System (PS) and a MicroBlaze or Custom Logic (PL) without stalling the processor.
*   **Addressing**: Note that the BRAM Controller address map seen by the PS might differ from the PL side; ensure base addresses are configured correctly in the Address Editor.

## Usage
1.  Write data to BRAM from Port A (e.g., PS).
2.  Read data from BRAM via Port B (e.g., PL/MicroBlaze).
