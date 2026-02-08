
`timescale 1ns / 1ps

module mag_squared (
    input  wire        aclk,
    input  wire        aresetn,
    
    // Slave AXI-Stream Interface (From FFT)
    input  wire [31:0] s_axis_tdata,   // [15:0] Real, [31:16] Imag
    input  wire [3:0]  s_axis_tkeep,   // Added for DMA compatibility
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,
    
    // Master AXI-Stream Interface (To DMA/Memory)
    output wire [31:0] m_axis_tdata,   // Calculated Power Magnitude
    output wire [3:0]  m_axis_tkeep,   // Added for DMA compatibility
    output wire        m_axis_tvalid,
    output wire        m_axis_tlast,
    input  wire        m_axis_tready
);

    // Pass through TKEEP (DMA requires it usually)
    assign m_axis_tkeep = s_axis_tkeep;

    // Combinational Logic for Power Calculation
    // Assuming input is packed 16-bit Real, 16-bit Imaginary (standard FFT output)
    wire signed [15:0] real_val = s_axis_tdata[15:0];
    wire signed [15:0] imag_val = s_axis_tdata[31:16];
    
    wire signed [31:0] re_sq = real_val * real_val;
    wire signed [31:0] im_sq = imag_val * imag_val;
    
    // Output Result
    // Pipeline register could be added here for timing if needed, 
    // but kept combinational for simplicity at < 100MHz.
    assign m_axis_tdata = re_sq + im_sq;

    // AXI Stream Handshake Logic
    // --------------------------
    // Custom block is always ready to accept data (combinational throughput).
    // It only stalls if the downstream master (DMA) is not ready.
    assign s_axis_tready = m_axis_tready;
    
    // Valid and Last signals pass through directly
    // (Data is valid if input is valid AND output is ready/accepted)
    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tlast  = s_axis_tlast;

endmodule
