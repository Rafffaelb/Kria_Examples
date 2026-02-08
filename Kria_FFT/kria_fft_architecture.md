# Kria FFT Architecture Diagram
View this file in VS Code or GitHub to see the rendered block diagram.


```mermaid
graph LR
    %% Styles
    style PS fill:#ffcccc,stroke:#b71c1c,stroke-width:2px
    style MB fill:#bbdefb,stroke:#0d47a1,stroke-width:2px
    style DMA fill:#ffecb3,stroke:#ff6f00,stroke-width:2px
    style FFT fill:#fff9c4,stroke:#fbc02d,stroke-width:2px
    style PowerCalc fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,stroke-dasharray: 5 5
    style SharedBRAM fill:#b2dfdb,stroke:#00695c,stroke-width:2px

    subgraph Processing_System [Zynq UltraScale+ MPSoC]
        PS[Cortex-A53 APU]
    end

    subgraph Control_PL [MicroBlaze Subsystem]
        MB[MicroBlaze Soft Core]
        SMC_MB[SmartConnect (Control)]
        INTC[Interrupt Controller]
    end

    subgraph Memory [Memory Subsystem]
        BRAM_Ctrl_A[BRAM Ctrl A]
        BRAM_Ctrl_B[BRAM Ctrl B]
        SharedBRAM[(True Dual Port BRAM)]
        SMC_PS[SmartConnect (High Perf)]
    end

    subgraph Acceleration [Hardware Pipeline]
        DMA[AXI DMA Controller]
        FFT[Xilinx FFT IP]
        PowerCalc[Custom Mag^2 Block]
    end

    subgraph Peripherals
        IIC[AXI IIC]
        Sensor((ADXL345))
    end

    %% Connections
    %% Control Flow
    MB -->|AXI-Lite| SMC_MB
    SMC_MB -->|Config| DMA
    SMC_MB -->|Control| IIC
    SMC_MB -->|Control| BRAM_Ctrl_A
    SMC_MB -->|Intr Status| INTC
    
    %% Interrupts
    INTC -.->|IRQ| MB
    IIC -.->|Intr| INTC
    DMA -.->|Intr| INTC

    %% Data Flow (Memory)
    PS <==>|AXI HPM0| SMC_PS
    DMA ==>|M_AXI_MM2S| SMC_PS
    DMA ==>|M_AXI_S2MM| SMC_PS
    
    SMC_PS ==>|AXI4| BRAM_Ctrl_B
    BRAM_Ctrl_B <==>|Port B| SharedBRAM
    BRAM_Ctrl_A <==>|Port A| SharedBRAM

    %% Streaming Pipeline (High Speed)
    DMA ==>|Stream (Samples)| FFT
    FFT ==>|Stream (Re, Im)| PowerCalc
    PowerCalc ==>|Stream (Power)| DMA

    %% IO
    IIC ---|I2C Wire| Sensor
```
