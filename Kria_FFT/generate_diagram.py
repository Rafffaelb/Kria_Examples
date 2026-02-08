
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
    # Initialize Digraph
    dot = Digraph(comment='Kria FFT Architecture', format='png')
    dot.attr(dpi='300')             # High Resolution
    dot.attr(rankdir='LR')          # Left-to-Right layout
    dot.attr(splines='polyline')    # Neater edges
    dot.attr(ranksep='1.8')         # WIDER COLUMNS
    dot.attr(nodesep='1.0')         # MORE SPACE BETWEEN NODES
    dot.attr(bgcolor='white')
    
    # Global Font Settings
    dot.attr('node', fontname='Arial', fontsize='16')
    dot.attr('edge', fontname='Arial', fontsize='14', penwidth='2.0', arrowsize='1.2')

    # Color Palette
    c_ps = '#ffebee'      # Red-ish
    c_mb = '#e3f2fd'      # Blue-ish
    c_mem = '#e0f2f1'     # Teal-ish
    c_acc = '#fffde7'     # Yellow-ish
    c_periph = '#f3e5f5'  # Purple-ish

    # --- Processing System (PS) ---
    with dot.subgraph(name='cluster_ps') as c:
        c.attr(label='Processing System (PS)', fontsize='20', style='dashed', bgcolor='#fafafa', pencolor='#bdbdbd')
        # HTML Label for Rich Text
        lbl = '''<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0">
                 <TR><TD><B>Zynq UltraScale+</B></TD></TR>
                 <TR><TD>Application Core</TD></TR>
                 <TR><TD><I>(Monitor App)</I></TD></TR>
                 </TABLE>>'''
        c.node('Zynq', lbl, shape='component', fillcolor=c_ps, color='#e57373', height='1.5')

    # --- Control Subsystem (PL) ---
    with dot.subgraph(name='cluster_control') as c:
        c.attr(label='Control Plane (MicroBlaze)', fontsize='20', style='dashed', bgcolor='#f5faff', pencolor='#90caf9')
        
        lbl_mb = '''<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0">
                    <TR><TD><B>MicroBlaze</B></TD></TR>
                    <TR><TD>Soft Processor</TD></TR>
                    <TR><TD><I>(Controller App)</I></TD></TR>
                    </TABLE>>'''
        c.node('MicroBlaze', lbl_mb, shape='box', style='filled,rounded', fillcolor=c_mb, color='#64b5f6', height='1.2')
        
        c.node('SMC_MB', 'AXI SmartConnect\n(Control)', shape='octagon', fillcolor='white', color='#64b5f6', style='dashed,filled')
        c.node('INTC', 'Interrupt\nController', shape='box', style='filled,rounded', fillcolor=c_mb, color='#64b5f6')

    # --- Acceleration Pipeline ---
    with dot.subgraph(name='cluster_accel') as c:
        c.attr(label='Hardware Acceleration Pipeline', fontsize='20', style='dashed', bgcolor='#fffde7', pencolor='#fff176')
        
        lbl_dma = '''<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0">
                     <TR><TD><B>AXI DMA</B></TD></TR>
                     <TR><TD>Direct Memory Access</TD></TR>
                     </TABLE>>'''
        c.node('DMA', lbl_dma, shape='box', style='filled,rounded', fillcolor=c_acc, color='#ffd54f', height='1.2')
        
        lbl_fft = '''<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0">
                     <TR><TD><B>Xilinx FFT</B></TD></TR>
                     <TR><TD>Streaming Core</TD></TR>
                     </TABLE>>'''
        c.node('FFT', lbl_fft, shape='box', style='filled,rounded', fillcolor='#fff9c4', color='#fbc02d', penwidth='3.0', height='1.2')
        
        lbl_pow = '''<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0">
                     <TR><TD><B>Power Calc</B></TD></TR>
                     <TR><TD>Custom RTL</TD></TR>
                     <TR><TD><I>(mag_squared.v)</I></TD></TR>
                     </TABLE>>'''
        c.node('PowerCalc', lbl_pow, shape='component', style='filled', fillcolor='#ffecb3', color='#ff6f00', penwidth='3.0', height='1.2')

    # --- Memory Subsystem ---
    with dot.subgraph(name='cluster_mem') as c:
        c.attr(label='Shared Memory', fontsize='20', style='dashed', bgcolor='#e0f2f1', pencolor='#80cbc4')
        
        c.node('SMC_PS', 'AXI SmartConnect\n(High Performance)', shape='octagon', fillcolor='white', color='#4db6ac', style='dashed,filled')
        c.node('BRAM_Ctrl_A', 'BRAM Port A\n(MicroBlaze)', fontsize='14', fillcolor='white', color='#80cbc4')
        c.node('BRAM_Ctrl_B', 'BRAM Port B\n(DMA / Zynq)', fontsize='14', fillcolor='white', color='#80cbc4')
        
        lbl_bram = '''<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0">
                      <TR><TD><B>Shared BRAM</B></TD></TR>
                      <TR><TD>True Dual Port</TD></TR>
                      <TR><TD><I>Data Buffer</I></TD></TR>
                      </TABLE>>'''
        c.node('BRAM', lbl_bram, shape='cylinder', style='filled', fillcolor='#b2dfdb', color='#009688', height='1.5', width='2.0')

    # --- Peripherals ---
    with dot.subgraph(name='cluster_periph') as c:
        c.attr(label='I/O', fontsize='20', style='dashed', bgcolor='#f3e5f5', pencolor='#ce93d8')
        c.node('IIC', 'AXI IIC', shape='box', style='filled,rounded', fillcolor=c_periph, color='#ba68c8')
        c.node('Sensor', 'ADXL345\nAccelerometer', shape='ellipse', style='filled', fillcolor='#e1bee7', color='#8e24aa', height='1.0')

    # --- Connections (Story Flow) ---
    
    # 1. ACQUISITION
    dot.edge('Sensor', 'IIC', label='1. I2C Data', color='#8e24aa', penwidth='3.0', dir='back')
    dot.edge('IIC', 'SMC_MB', color='#8e24aa', penwidth='2.0', dir='back')
    dot.edge('SMC_MB', 'MicroBlaze', label='2. Read', color='#8e24aa', penwidth='2.0', dir='back')
    
    dot.edge('MicroBlaze', 'SMC_MB', color='#8e24aa', penwidth='2.0') 
    dot.edge('SMC_MB', 'BRAM_Ctrl_A', label='3. Write Buffer', color='#8e24aa', penwidth='3.0')
    dot.edge('BRAM_Ctrl_A', 'BRAM', color='#8e24aa', penwidth='3.0')

    # 2. CONTROL HAND-OFF
    dot.edge('SMC_MB', 'DMA', label='4. Start DMA', color='#1565c0', penwidth='2.5', style='dashed')

    # 3. PROCESSING PHASE (DMA)
    dot.edge('BRAM', 'BRAM_Ctrl_B', color='#ef6c00', penwidth='3.0', dir='both')
    dot.edge('BRAM_Ctrl_B', 'SMC_PS', color='#ef6c00', penwidth='3.0', dir='both')
    
    # Read Path
    dot.edge('SMC_PS', 'DMA', label='5. Fetch', color='#ef6c00', penwidth='3.0', dir='back')
    dot.edge('DMA', 'FFT', label='6. Samples', color='#ef6c00', penwidth='4.0')
    
    # Pipeline
    dot.edge('FFT', 'PowerCalc', label='7. Re/Im', color='#ef6c00', penwidth='4.0')
    dot.edge('PowerCalc', 'DMA', label='8. Power', color='#ef6c00', penwidth='4.0')
    
    # Write Path
    dot.edge('DMA', 'SMC_PS', label='9. Write Back', color='#ef6c00', penwidth='3.0')

    # 4. BACKGROUND / IRQ
    dot.edge('MicroBlaze', 'SMC_MB', style='invis') 
    dot.edge('SMC_MB', 'INTC', style='dashed', color='#90caf9')
    
    # Interrupts
    dot.edge('DMA', 'INTC', label='10. IRQ', style='dotted', color='#757575')
    dot.edge('INTC', 'MicroBlaze', style='dotted', color='#757575')

    # Zynq Access
    dot.edge('Zynq', 'SMC_PS', label='Read', style='dashed', color='#bdbdbd')

    # Title
    lbl_title = '''<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0">
                   <TR><TD><FONT POINT-SIZE="28"><B>Kria FFT System Architecture</B></FONT></TD></TR>
                   <TR><TD><FONT POINT-SIZE="18">Hardware Acceleration Data Flow</FONT></TD></TR>
                   </TABLE>>'''
    dot.attr(label=lbl_title, labelloc='t')

    # Render
    output_path = dot.render(filename='kria_fft_architecture_hq', cleanup=True)
    print(f"High-Quality Diagram Generated: {output_path}")

if __name__ == '__main__':
    create_kria_fft_diagram()
