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