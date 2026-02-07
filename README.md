<<<<<<< HEAD
# Workflow para Execução dos Exemplos Kria

Este documento descreve o fluxo de trabalho para executar os exemplos Kria, incluindo a geração do design de hardware usando scripts TCL no Vivado e a implementação do software correspondente no Xilinx Vitis.

## Pré-requisitos

Antes de começar, certifique-se de ter instalado:
- Xilinx Vivado Design Suite (2020.1 ou posterior recomendado)
- Xilinx Vitis Unified Software Platform
- Placa de desenvolvimento compatível com Xilinx Kria (KV260/KV240)

## Estrutura do Projeto

Cada exemplo segue esta estrutura:
```
Exemplo/
├── Vivado/
│   └── design_1.tcl     # Script TCL para geração do design de hardware
└── Vitis/
    ├── src/             # Código fonte C/C++
    └── projeto_vitis/   # Projeto exportado do Vivado (se aplicável)
```

## Fluxo de Trabalho

### 1. Geração do Design de Hardware (Vivado)

1. Abra o Xilinx Vivado
2. Execute o script TCL:
   ```
   source Kria_Examples/[NOME_EXEMPLO]/Vivado/design_1.tcl
   ```
   
   Ou alternativamente:
   - File → Source → Navigate to TCL script
   - Selecione o arquivo `design_1.tcl` do exemplo desejado

3. Após a execução do script, o design será gerado automaticamente
4. Revise o design conforme necessário
5. Gere o bitstream:
   - Flow Navigator → Generate Bitstream
   - Clique em "Yes" para executar as etapas de síntese e implementação

6. Exporte o hardware para o Vitis:
   - File → Export → Export Hardware
   - Selecione "Include bitstream"
   - Escolha um local para salvar o arquivo `.xsa`

### 2. Configuração do Ambiente de Software (Vitis)

1. Abra o Xilinx Vitis
2. Crie um novo workspace:
   - File → Switch Workspace → Other
   - Selecione ou crie uma pasta para o workspace

3. Importe o hardware:
   - File → New → Application Project
   - Na caixa de diálogo "Platform", selecione "Create a new platform from hardware (XSA)"
   - Navegue até o arquivo `.xsa` gerado no Vivado
   - Clique em "Next"

4. Configure o projeto:
   - Nomeie o projeto (ex: i2c_example)
   - Certifique-se de que "Create a new application" está selecionado
   - Clique em "Next"

5. Selecione um template (opcional):
   - Para exemplos simples, você pode escolher "Empty Application"
   - Clique em "Finish"

### 3. Adicionando Código Fonte

1. No explorador do projeto, expanda a pasta do projeto
2. Navegue até a pasta "src" (crie se não existir)
3. Adicione os arquivos de código fonte do exemplo:
   - Copie os arquivos `.c/.cpp/.h` da pasta `Vitis/src` do exemplo
   - Cole-os na pasta src do seu projeto no Vitis

4. Para os exemplos ADXL345, certifique-se de incluir:
   - `ADXL345.cpp` e `ADXL345.h` (driver do sensor)
   - `axiWire.hpp` (biblioteca de comunicação I2C)
   - Arquivo principal (`example.cpp`, `iic_example.cpp`, etc.)

### 4. Compilação e Execução

1. Compile o projeto:
   - Clique com botão direito no projeto → Build Project
   - Ou clique no ícone "Build" na barra de ferramentas

2. Conecte a placa Kria:
   - Certifique-se de que a placa está conectada via JTAG
   - Ligue a placa

3. Programe o dispositivo:
   - Clique com botão direito no projeto → Run As → Launch Hardware
   - Ou selecione "Xilinx -> Program Device" na barra de ferramentas

4. Execute o aplicativo:
   - No explorador, clique com botão direito no ELF file
   - Selecione "Run As -> Launch on Hardware (System Debugger)"

### 5. Monitoramento e Debugging

1. Para visualizar a saída serial:
   - Utilize um terminal serial (como TeraTerm ou PuTTY)
   - Configure a conexão com os parâmetros da porta UART da placa
   - Velocidade típica: 115200 baud

2. Para debugging:
   - Defina breakpoints no código
   - Use as perspectivas de debug do Vitis
   - Monitore variáveis e registradores conforme necessário

## Notas Específicas por Exemplo

### Exemplo I2C
- Lê continuamente dados do acelerômetro ADXL345 via I2C
- Exibe valores X, Y, Z no terminal serial
- Não utiliza interrupções

### Exemplo INTC_IIC
- Similar ao exemplo I2C, mas usa interrupções
- Requer configuração correta do controlador de interrupção (INTC)
- Mais eficiente em termos de uso da CPU

### Exemplo INTC_IIC_uB
- Usa MicroBlaze para ler dados do sensor
- Armazena dados em BRAM compartilhada
- Requer configuração de dois processadores (Cortex-A53 e MicroBlaze)

### Exemplo SharedBram
- Demonstra comunicação entre dois processadores via BRAM
- Um processador escreve dados, outro os lê
- Útil para entender mecanismos de comunicação inter-processador

## Solução de Problemas

### Problemas Comuns

1. **Falha na geração do bitstream**
   - Verifique se todas as conexões no design estão corretas
   - Confirme que todos os IPs necessários estão incluídos

2. **Erros de compilação no Vitis**
   - Verifique se todos os arquivos de origem foram adicionados corretamente
   - Confirme se os caminhos das bibliotecas estão configurados

3. **Falha na programação do dispositivo**
   - Verifique as conexões JTAG
   - Confirme que a placa está ligada e sendo reconhecida

4. **Nenhuma saída no terminal serial**
   - Verifique as configurações da porta UART (velocidade, paridade, etc.)
   - Confirme que o código está enviando dados para a UART
=======

# Kria FFT - Hardware & Software Implementation Guide
# ===================================================

This repository contains the Vivado and Vitis project files for implementing an FFT-based signal processing system on the Kria KR260 Robotics Starter Kit.

## Key Features
*   **Sensor Interface**: I2C communication with ADXL345 Accelerometer.
*   **Processing Core**: MicroBlaze Soft Processor for control and data acquisition.
*   **Hardware Acceleration**: Custom Verilog module for high-speed Power Calculation ($Real^2 + Imag^2$).
*   **Memory Architecture**: Shared BRAM between MicroBlaze and Zynq MPSoC for data transfer.
*   **Simulation**: SystemVerilog testbench for verification.

## 1. Directory Structure

| File/Folder | Description |
| :--- | :--- |
| `build_kria_fft.tcl` | **Main Script**: Builds the complete Vivado project from scratch. |
| `add_power_block.tcl` | **Hardware Upgrade**: Adds the custom `mag_squared` module to the Block Design. |
| `build_bitstream.tcl` | **Implementation**: Runs Synthesis, Implementation, and generates Bitstream/XSA. |
| `mag_squared.v` | **Custom RTL**: Verilog module for calculating signal power magnitude. |
| `adxl345.xdc` | **Constraints**: Physical pin entries for PMOD 1 I2C connections. |
| `sim/tb_system.sv` | **Simulation**: Testbench for verifying system connectivity. |
| `sw/main.c` | **Software**: MicroBlaze application C code. |
| `PC_FFT_Test.c` | **PC Verification**: C program to test FFT logic independently on a PC. |

## 2. Hardware Implementation (Vivado)

### Step 1: Build the Base System
Open Vivado 2025.2, start the Tcl Console, and navigate to this directory:
```tcl
cd c:/Users/rafam/Documents/TU_Dresden/Kria_FFT
source build_kria_fft.tcl
```
*   This creates the project, block design, and configures the Zynq/MicroBlaze/BRAM.
*   **Fix**: Uses SmartConnect to avoid persistent AXI Interconnect bugs.

### Step 2: Add Custom Hardware Acceleration
Add the custom Power Calculation block:
```tcl
source add_power_block.tcl
```
*   Adds `mag_squared.v` to the block design.
*   Adds AXI GPIOs to interface the calculator with MicroBlaze.

### Step 3: Add Constraints
The ADXL345 sensor is connected to **PMOD 1** (Right Angle Connector, Top Row).
*   **SCL**: Pin H12 (PMOD 1, Pin 3)
*   **SDA**: Pin E10 (PMOD 1, Pin 4)
The `fix_bitstream.tcl` script adds these constraints automatically.

### Step 4: Generate Bitstream & Export Hardware
Run the full build flow:
```tcl
source fix_bitstream.tcl
```
*   Synthesizes the design.
*   Implements (Place & Route).
*   Generates `system_wrapper.bit`.
*   Exports `Kria_FFT.xsa` for Vitis.

## 3. Simulation
To verify the design logic:
```tcl
source launch_sim.tcl
```
*   Compiles `sim/tb_system.sv`.
*   Launches Vivado Simulator.

To verify the FFT Mathematics functionality purely on PC:
```bash
gcc PC_FFT_Test.c -o fft_test -lm
./fft_test
```

## 4. Software Implementation (Vitis)

The MicroBlaze application (`sw/main.c`) reads accelerometer data, processes it, and stores results.

### Using the Hardware Power Calculator
The custom block is accessed via AXI GPIO.
*   **GPIO Output (Base Address)**: Send packed 32-bit (16-bit Imag | 16-bit Real).
*   **GPIO Input (Base Address)**: Read 32-bit Power result.

**Example C Code Snippet:**
```c
#include "xgpio.h"

// Instance
XGpio GpioOut, GpioIn;

// Initialize
XGpio_Initialize(&GpioOut, XPAR_AXI_GPIO_OUT_DEVICE_ID);
XGpio_Initialize(&GpioIn, XPAR_AXI_GPIO_IN_DEVICE_ID);

// Processing Loop
for (int i=0; i<NUM_SAMPLES; i++) {
    // 1. Pack Data
    short real = fft_real[i];
    short imag = fft_imag[i];
    u32 input_val = (imag << 16) | (real & 0xFFFF);
    
    // 2. Hardware Compute
    XGpio_DiscreteWrite(&GpioOut, 1, input_val);
    u32 power = XGpio_DiscreteRead(&GpioIn, 1);
    
    // 3. Store
    result_buffer[i] = power;
}
```

## 5. Next Steps
1.  Import `Kria_FFT.xsa` into Vitis Unified IDE.
2.  Create a "Platform Component" from the XSA.
3.  Create an "Application Component" using the Platform.
4.  Copy code from `sw/main.c` (adapt for GPIO usage as shown above).
5.  Build and Run on Hardware.
>>>>>>> 8d984af (Initial commit for Kria_FFT Project)
