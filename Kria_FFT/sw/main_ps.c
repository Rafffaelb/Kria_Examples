
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "sleep.h"

// --- Helper Macros ---
// NOTE: Verify these addresses in Vivado Address Editor for the PS View
#define SHARED_BRAM_BASE    0xC0000000 
#define RX_BUFFER_OFFSET    0x0000  // Raw Data (Input)
#define TX_BUFFER_OFFSET    0x1000  // Processed Data (Output)
#define FLAG_OFFSET         0x2000  // Handshake Flag

#define TX_BUFFER_ADDR      (SHARED_BRAM_BASE + TX_BUFFER_OFFSET)
#define FLAG_ADDR           (SHARED_BRAM_BASE + FLAG_OFFSET)

// --- Constants ---
#define FFT_SIZE            1024
#define DATA_READY_FLAG     0xCAFEBABE
#define DATA_ACK_FLAG       0x00000000

int main()
{
    init_platform();
    print("--- Kria FFT System Monitor (PS) ---\n\r");
    print("Waiting for data from MicroBlaze...\n\r");

    // Clear any stale flags
    Xil_Out32(FLAG_ADDR, DATA_ACK_FLAG);

    u32 frame_count = 0;

    while (1) {
        // 1. Poll Flag
        volatile u32 flag = Xil_In32(FLAG_ADDR);
        
        if (flag == DATA_READY_FLAG) {
            frame_count++;
            
            // 2. Read Results from BRAM
            // Note: We need to invalidate cache to ensure we read fresh data from BRAM
            Xil_DCacheInvalidateRange((UINTPTR)TX_BUFFER_ADDR, FFT_SIZE * 4);
            
            xil_printf("Frame %d Received! Processing results...\n\r", frame_count);
            
            volatile u32 *fft_results = (u32 *)TX_BUFFER_ADDR;
            
            // Example: Find Peer Frequency (Max Magnitude)
            u32 max_power = 0;
            int max_idx = 0;
            
            for (int i = 0; i < FFT_SIZE/2; i++) { // Only look at positive frequencies
                u32 power = fft_results[i];
                if (power > max_power) {
                    max_power = power;
                    max_idx = i;
                }
            }
            
            xil_printf("  - Peak Frequency Bin: %d\n\r", max_idx);
            xil_printf("  - Peak Power: %u\n\r", max_power);
            
            // 3. Acknowledge Receipt (Clear Flag)
            Xil_Out32(FLAG_ADDR, DATA_ACK_FLAG);
        }
        
        usleep(1000); // Check every 1ms
    }

    cleanup_platform();
    return 0;
}
