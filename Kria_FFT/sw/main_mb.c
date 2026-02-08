
#include "xparameters.h"
#include "xaxidma.h"
#include "xiic.h"
#include "xil_io.h"
#include "xdebug.h"
#include "sleep.h"

// --- Hardware Configuration ---
#define DMA_DEV_ID          XPAR_AXIDMA_0_DEVICE_ID
#define IIC_DEV_ID          XPAR_AXI_IIC_0_DEVICE_ID
#define BRAM_BASE_ADDR      XPAR_MB_BRAM_CTRL_S_AXI_BASEADDR  // 0xC0000000 usually

// --- Memory Map (Shared BRAM) ---
// We split the BRAM into sections for Raw Data, Processed Data, and Flags
#define RX_BUFFER_OFFSET    0x0000  // Raw Time-Domain Samples (Input to FFT)
#define TX_BUFFER_OFFSET    0x1000  // Processed Freq-Domain Power (Output from FFT)
#define FLAG_OFFSET         0x2000  // Handshake Flag Address used by PS

#define RX_BUFFER_ADDR      (BRAM_BASE_ADDR + RX_BUFFER_OFFSET)
#define TX_BUFFER_ADDR      (BRAM_BASE_ADDR + TX_BUFFER_OFFSET)
#define FLAG_ADDR           (BRAM_BASE_ADDR + FLAG_OFFSET)

// --- Constants ---
#define FFT_SIZE            1024
#define SAMPLE_SIZE_BYTES   4       // 32-bit (16-bit Re + 16-bit Im)
#define DMA_TRANSFER_SIZE   (FFT_SIZE * SAMPLE_SIZE_BYTES)

#define DATA_READY_FLAG     0xCAFEBABE
#define DATA_ACK_FLAG       0x00000000

// --- Global Driver Instances ---
XAxiDma AxiDma;
XIic Iic;

int init_drivers() {
    int Status;
    XAxiDma_Config *CfgPtr;

    // 1. Initialize DMA
    CfgPtr = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!CfgPtr) {
        xil_printf("No config found for %d\r\n", DMA_DEV_ID);
        return XST_FAILURE;
    }

    Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
    if (Status != XST_SUCCESS) {
        xil_printf("Initialization failed %d\r\n", Status);
        return XST_FAILURE;
    }

    // Disable Interrupts for Polling Mode initially
    XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

    // 2. Initialize I2C (Optional: Add actual sensor init here)
    // Status = XIic_Initialize(&Iic, IIC_DEV_ID);
    // ...

    return XST_SUCCESS;
}

void acquire_sensor_data() {
    // Simulate reading I2C sensor data and writing to BRAM
    // In real app, loop over I2C reads here.
    
    volatile u32 *rx_ptr = (u32 *)RX_BUFFER_ADDR;
    
    for (int i = 0; i < FFT_SIZE; i++) {
        // Generate dummy sine wave or simpler pattern for test
        // Packing: [31:16] Imag (0), [15:0] Real (Sample)
        int16_t sample = (int16_t)(i % 256); // Dummy sawtooth
        u32 packed_data = (0 << 16) | (sample & 0xFFFF);
        
        rx_ptr[i] = packed_data;
    }
    
    // Flush Data Cache to ensure DMA sees updated BRAM content (if cache enabled)
    Xil_DCacheFlushRange((UINTPTR)RX_BUFFER_ADDR, DMA_TRANSFER_SIZE);
}

int run_hardware_acceleration() {
    int Status;

    // 1. Invalidate Cache for Result Buffer (So CPU reads fresh data from DMA)
    Xil_DCacheInvalidateRange((UINTPTR)TX_BUFFER_ADDR, DMA_TRANSFER_SIZE);

    // 2. Start DMA Transfer: MM2S (Read from BRAM -> FFT)
    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)RX_BUFFER_ADDR,
                                   DMA_TRANSFER_SIZE, XAXIDMA_DMA_TO_DEVICE);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    // 3. Start DMA Transfer: S2MM (Write FFT Result -> BRAM)
    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)TX_BUFFER_ADDR,
                                   DMA_TRANSFER_SIZE, XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    // 4. Wait for Completion (Polling)
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
        // Wait for MM2S
    }
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)) {
        // Wait for S2MM
    }

    return XST_SUCCESS;
}

int main() {
    init_platform();
    xil_printf("--- MicroBlaze FFT Controller ---\r\n");

    if (init_drivers() != XST_SUCCESS) {
        xil_printf("Driver Init Failed.\r\n");
        return 1;
    }

    while (1) {
        // 1. Acquire Data (I2C -> BRAM)
        xil_printf("Acquiring Data...\r\n");
        acquire_sensor_data();

        // 2. Run Hardware Acceleration (BRAM -> DMA -> FFT -> BRAM)
        xil_printf("Running FFT Acceleration...\r\n");
        if (run_hardware_acceleration() != XST_SUCCESS) {
            xil_printf("DMA Transfer Failed\r\n");
            break;
        }

        // 3. Signal PS that data is ready
        xil_printf("Data Ready. Signaling PS...\r\n");
        Xil_Out32(FLAG_ADDR, DATA_READY_FLAG);

        // 4. Wait for PS to Acknowledge (Clear Flag)
        while (Xil_In32(FLAG_ADDR) == DATA_READY_FLAG) {
            sleep(1); // Wait 1ms
        }
        
        // Loop
        sleep(100); // 100ms delay between frames
    }

    cleanup_platform();
    return 0;
}
