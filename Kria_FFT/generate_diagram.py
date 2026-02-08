
import os

# Try to find Graphviz executable in common locations and add to PATH temporarily
possible_paths = [
    r"C:\Program Files\Graphviz\bin",
    r"C:\Program Files (x86)\Graphviz\bin",
    r"C:\Graphviz\bin"
]

for path in possible_paths:
    if os.path.exists(path):
        print(f"Found Graphviz at: {path}")
        os.environ["PATH"] += os.pathsep + path
        break

try:
    from graphviz import Digraph
except ImportError:
    print("Error: 'graphviz' library is missing. Run: pip install graphviz")
    exit(1)

def create_kria_fft_diagram():
    # Initialize Digraph with high resolution and professional settings
    dot = Digraph(comment='Kria FFT Architecture', format='png')
    dot.attr(dpi='300')             # High Resolution
    dot.attr(rankdir='LR')          # Left-to-Right layout
    dot.attr(splines='polyline')    # Neater edges than 'ortho'
    dot.attr(ranksep='1.2')         # More space between columns
    dot.attr(nodesep='0.8')         # More space between nodes
    dot.attr(bgcolor='white')
    
    # Default Node Style
    dot.attr('node', 
             shape='box', 
             style='filled,rounded', # Rounded corners
             fontname='Helvetica', 
             fontsize='12',
             penwidth='1.5',
             margin='0.2,0.1')
             
    # Default Edge Style
    dot.attr('edge', 
             fontname='Helvetica', 
             fontsize='10',
             penwidth='1.2',
             arrowsize='0.8')

    # Color Palette
    c_ps = '#ffebee'      # Red-ish (Zynq)
    c_mb = '#e3f2fd'      # Blue-ish (Control)
    c_mem = '#e0f2f1'     # Teal-ish (Memory)
    c_acc = '#fff8e1'     # Yellow-ish (Acceleration)
    c_periph = '#f3e5f5'  # Purple-ish (IO)

    # --- Processing System (PS) ---
    with dot.subgraph(name='cluster_ps') as c:
        c.attr(label='Processing System (PS)', fontname='Helvetica-Bold', fontsize='14', style='dashed', bgcolor='#fafafa', pencolor='#bdbdbd')
        c.node('Zynq', 'Zynq UltraScale+\nMPSoC (Cortex-A53)\n[AXI Master]', fillcolor=c_ps, color='#e57373')

    # --- Control Subsystem (PL) ---
    with dot.subgraph(name='cluster_control') as c:
        c.attr(label='Control Subsystem (MicroBlaze)', fontname='Helvetica-Bold', fontsize='14', style='dashed', bgcolor='#f5faff', pencolor='#90caf9')
        c.node('MicroBlaze', 'MicroBlaze\nSoft Processor', fillcolor=c_mb, color='#64b5f6')
        c.node('SMC_MB', 'AXI SmartConnect\n(Control Interconnect)', shape='octagon', fillcolor='#ffffff', color='#64b5f6', style='dashed,rounded')
        c.node('INTC', 'Interrupt\nController', fillcolor=c_mb, color='#64b5f6')

    # --- Acceleration Pipeline ---
    with dot.subgraph(name='cluster_accel') as c:
        c.attr(label='Hardware Acceleration Pipeline', fontname='Helvetica-Bold', fontsize='14', style='dashed', bgcolor='#fffde7', pencolor='#fff176')
        
        c.node('DMA', 'AXI DMA\n(Direct Memory Access)', fillcolor=c_acc, color='#ffd54f')
        
        # Highlighted FFT and Custom Block
        c.node('FFT', 'Xilinx FFT IP\n(Pipelined Streaming)', fillcolor='#fff9c4', color='#fbc02d', penwidth='2.0')
        c.node('PowerCalc', 'Custom Power Calc\n(mag_squared.v)', fillcolor='#ffecb3', color='#ff6f00', penwidth='2.0', shape='component')

    # --- Memory Subsystem ---
    with dot.subgraph(name='cluster_mem') as c:
        c.attr(label='Shared Memory Subsystem', fontname='Helvetica-Bold', fontsize='14', style='dashed', bgcolor='#e0f2f1', pencolor='#80cbc4')
        
        c.node('SMC_PS', 'AXI SmartConnect\n(High Performance)', shape='octagon', fillcolor='#ffffff', color='#4db6ac', style='dashed,rounded')
        c.node('BRAM_Ctrl_A', 'BRAM Ctrl A\n(Port A)', fontsize='10', fillcolor='#ffffff', color='#80cbc4')
        c.node('BRAM_Ctrl_B', 'BRAM Ctrl B\n(Port B)', fontsize='10', fillcolor='#ffffff', color='#80cbc4')
        c.node('BRAM', 'Shared BRAM\n(True Dual Port)', shape='cylinder', fillcolor='#b2dfdb', color='#009688', height='1.0')

    # --- Peripherals ---
    with dot.subgraph(name='cluster_periph') as c:
        c.attr(label='External I/O', fontname='Helvetica-Bold', fontsize='14', style='dashed', bgcolor='#f3e5f5', pencolor='#ce93d8')
        c.node('IIC', 'AXI IIC', fillcolor=c_periph, color='#ba68c8')
        c.node('Sensor', 'ADXL345\nAccelerometer', shape='ellipse', fillcolor='#e1bee7', color='#8e24aa')

    # --- Connections ---
    
    # 1. Control Plane (MicroBlaze -> Peripherals)
    #    Use explicit ports (n/s/e/w) to guide layout
    dot.edge('MicroBlaze', 'SMC_MB', label='M_AXI_DP', color='#1565c0')
    dot.edge('SMC_MB', 'IIC', color='#42a5f5')
    dot.edge('SMC_MB', 'INTC', color='#42a5f5')
    dot.edge('SMC_MB', 'DMA', label='AXI-Lite\n(Config)', color='#42a5f5', style='dashed')
    dot.edge('SMC_MB', 'BRAM_Ctrl_A', label='AXI-Lite', color='#42a5f5')

    # 2. Interrupts (Dotted Red)
    dot.edge('INTC', 'MicroBlaze', label='IRQ', color='#d32f2f', style='dotted', dir='back')
    dot.edge('IIC', 'INTC', color='#ef5350', style='dotted')
    dot.edge('DMA', 'INTC', color='#ef5350', style='dotted')

    # 3. Memory Data Path (High Bandwidth)
    #    Zynq -> BRAM
    dot.edge('Zynq', 'SMC_PS', label='AXI HPM0', color='#d84315', penwidth='2.0')
    #    DMA <-> BRAM
    dot.edge('DMA', 'SMC_PS', label='AXI MM2S/S2MM', color='#d84315', penwidth='2.0')
    
    dot.edge('SMC_PS', 'BRAM_Ctrl_B', label='AXI4', color='#00695c')
    dot.edge('BRAM_Ctrl_B', 'BRAM', label='Port B', color='#00695c')
    dot.edge('BRAM_Ctrl_A', 'BRAM', label='Port A', color='#00695c')

    # 4. Streaming Acceleration Pipeline (The "Cool" Part)
    #    Use 'same' rank to force straight line if needed, but subgraphs usually handle it.
    dot.edge('DMA', 'FFT', label='AXIS Stream\n(Samples)', color='#e65100', penwidth='2.5')
    dot.edge('FFT', 'PowerCalc', label='AXIS Stream\n(Re, Im)', color='#ef6c00', penwidth='2.5')
    dot.edge('PowerCalc', 'DMA', label='AXIS Stream\n(Power)', color='#f57c00', penwidth='2.5')

    # 5. External IO
    dot.edge('IIC', 'Sensor', label='I2C Bus', dir='both', color='#8e24aa', penwidth='1.5')

    # --- Legend / Title ---
    dot.attr(labelloc='t')
    dot.attr(label='Kria FFT System Architecture\nHigh-Performance Acceleration Pipeline', fontsize='20', fontname='Helvetica-Bold')

    # Render
    output_path = dot.render(filename='kria_fft_architecture_hq', cleanup=True)
    print(f"High-Quality Diagram Generated: {output_path}")

if __name__ == '__main__':
    create_kria_fft_diagram()
