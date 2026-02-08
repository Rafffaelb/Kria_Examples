
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

    # --- Connections (Story Flow) ---
    
    # Color Scheme for Paths
    c_control = '#90caf9'   # Light Blue (Config/Status)
    c_data_aq = '#ba68c8'   # Purple (Acquisition)
    c_data_proc = '#ef6c00' # Orange (High Speed Processing)
    
    # 1. ACQUISITION PHASE
    # Sensor -> IIC -> MicroBlaze -> BRAM
    dot.edge('Sensor', 'IIC', label='1. I2C Data', color=c_data_aq, penwidth='2.0', dir='back')
    dot.edge('IIC', 'SMC_MB', color=c_data_aq, penwidth='1.5', dir='back') # Data flows UP to MB
    dot.edge('SMC_MB', 'MicroBlaze', label='2. Read Samples', color=c_data_aq, penwidth='1.5', dir='back')
    
    dot.edge('MicroBlaze', 'SMC_MB', color=c_data_aq) # MB writes back out
    dot.edge('SMC_MB', 'BRAM_Ctrl_A', label='3. Write Buffer', color=c_data_aq, penwidth='2.0')
    dot.edge('BRAM_Ctrl_A', 'BRAM', color=c_data_aq, penwidth='2.0')

    # 2. CONTROL HAND-OFF
    # MicroBlaze tells DMA to start
    # We make this part of the numbered sequence now
    dot.edge('SMC_MB', 'DMA', label='4. Start Transfer\n(AXI-Lite)', color=c_control, penwidth='2.0', style='dashed')

    # 3. PROCESSING PHASE (DMA)
    # BRAM -> DMA -> FFT -> Mag -> DMA -> BRAM
    dot.edge('BRAM', 'BRAM_Ctrl_B', color=c_data_proc, penwidth='2.0', dir='both')
    dot.edge('BRAM_Ctrl_B', 'SMC_PS', color=c_data_proc, penwidth='2.0', dir='both')
    
    # Read Path
    dot.edge('SMC_PS', 'DMA', label='5. DMA Fetch\n(MM2S)', color=c_data_proc, penwidth='2.0', dir='back')
    dot.edge('DMA', 'FFT', label='6. Stream Samples', color=c_data_proc, penwidth='2.5')
    
    # Pipeline
    dot.edge('FFT', 'PowerCalc', label='7. FFT Result', color=c_data_proc, penwidth='2.5')
    dot.edge('PowerCalc', 'DMA', label='8. Power Mag', color=c_data_proc, penwidth='2.5')
    
    # Write Path
    dot.edge('DMA', 'SMC_PS', label='9. Write Back\n(S2MM)', color=c_data_proc, penwidth='2.0')

    # 4. BACKGROUND / IRQ
    dot.edge('MicroBlaze', 'SMC_MB', style='invis') 
    dot.edge('SMC_MB', 'INTC', style='dashed', color=c_control)
    
    # Interrupts
    dot.edge('DMA', 'INTC', label='10. Done (IRQ)', style='dotted', color='#bdbdbd')
    dot.edge('INTC', 'MicroBlaze', style='dotted', color='#bdbdbd')

    # Zynq Access (Optional debug path)
    dot.edge('Zynq', 'SMC_PS', label='Optional Access', style='dashed', color='#bdbdbd')

    # --- Legend / Title ---
    dot.attr(labelloc='t')
    dot.attr(label='Kria FFT System Architecture\nHigh-Performance Acceleration Pipeline', fontsize='20', fontname='Helvetica-Bold')

    # Render
    output_path = dot.render(filename='kria_fft_architecture_hq', cleanup=True)
    print(f"High-Quality Diagram Generated: {output_path}")

if __name__ == '__main__':
    create_kria_fft_diagram()
