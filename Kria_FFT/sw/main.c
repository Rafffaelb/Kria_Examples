
#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "xiic.h"
#include "math.h"
#include "complex.h"

// ----------------------------------------------------------------------------
// Configuration
// ----------------------------------------------------------------------------
// Adjust these IDs based on your final xparameters.h
#define IIC_DEVICE_ID       XPAR_AXI_IIC_0_DEVICE_ID
// Direct pointer to the Shared BRAM Base Address
// We use volatile to ensure the compiled code doesn't cache reads/writes
#define BRAM_BASE_ADDR      ((volatile u32*)XPAR_AXI_BRAM_CTRL_MB_S_AXI_BASEADDR)

#define ADXL345_ADDR        0x53
#define ADXL345_power_ctl   0x2D
#define ADXL345_data_format 0x31
#define ADXL345_datax0      0x32

#define SAMPLES_COUNT       128

// Structure for Complex Numbers
typedef struct {
    float real;
    float imag;
} complex_t;

// Global Buffers
complex_t signal[SAMPLES_COUNT];
XIic Iic;

// ----------------------------------------------------------------------------
// FFT Implementation
// ----------------------------------------------------------------------------
void fft(complex_t *X, int N) {
    if (N <= 1) return;

    complex_t even[N/2];
    complex_t odd[N/2];

    for (int i = 0; i < N/2; i++) {
        even[i] = X[2*i];
        odd[i] = X[2*i + 1];
    }

    fft(even, N/2);
    fft(odd, N/2);

    for (int k = 0; k < N/2; k++) {
        float r = even[k].real;
        float i = even[k].imag;
        
        float angle = -2 * M_PI * k / N;
        float wr = cos(angle);
        float wi = sin(angle);
        
        float tr = wr * odd[k].real - wi * odd[k].imag;
        float ti = wr * odd[k].imag + wi * odd[k].real;
        
        X[k].real = r + tr;
        X[k].imag = i + ti;
        
        X[k + N/2].real = r - tr;
        X[k + N/2].imag = i - ti;
    }
}

// ----------------------------------------------------------------------------
// I2C Helpers
// ----------------------------------------------------------------------------
int init_iic() {
    int Status;
    XIic_Config *ConfigPtr;

    ConfigPtr = XIic_LookupConfig(IIC_DEVICE_ID);
    if (ConfigPtr == NULL) return XST_FAILURE;

    Status = XIic_CfgInitialize(&Iic, ConfigPtr, ConfigPtr->BaseAddress);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    Status = XIic_Start(&Iic);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    return XST_SUCCESS;
}

void write_iic(u8 dev_addr, u8 reg, u8 data) {
    u8 buffer[2];
    buffer[0] = reg;
    buffer[1] = data;
    XIic_MasterSend(&Iic, buffer, 2);
}

void read_accel_data(short *x, short *y, short *z) {
    u8 write_buf[1] = {ADXL345_datax0};
    u8 read_buf[6];
    
    // Set register pointer
    XIic_MasterSend(&Iic, write_buf, 1);
    
    // Read 6 bytes
    XIic_MasterRecv(&Iic, read_buf, 6);
    
    *x = (short)((read_buf[1] << 8) | read_buf[0]);
    *y = (short)((read_buf[3] << 8) | read_buf[2]);
    *z = (short)((read_buf[5] << 8) | read_buf[4]);
}

// ----------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------
int main() {
    init_platform();
    xil_printf("\r\n--- Kria FFT Demo Start ---\r\n");

    if (init_iic() != XST_SUCCESS) {
        xil_printf("IIC Init Failed\r\n");
        return XST_FAILURE;
    }

    // Configure ADXL345
    xil_printf("Configuring Sensor...\r\n");
    write_iic(ADXL345_ADDR, ADXL345_power_ctl, 0x08);   // Measurement Mode
    write_iic(ADXL345_ADDR, ADXL345_data_format, 0x01); // +/- 4g

    // Pointer to Shared BRAM (floating point view)
    // We write 2 floats (Real, Imag) per sample.
    volatile float *bram_float_ptr = (volatile float *)BRAM_BASE_ADDR;

    while (1) {
        xil_printf("Acquiring %d samples...\r\n", SAMPLES_COUNT);

        // 1. Acquire
        for (int i = 0; i < SAMPLES_COUNT; i++) {
            short ax, ay, az;
            read_accel_data(&ax, &ay, &az);
            
            // Convert to float for FFT
            signal[i].real = (float)ax;
            signal[i].imag = 0.0f;
            
            // Delay to set roughly sampling rate
            for(volatile int k=0; k<2000; k++); 
        }

        // 2. Compute FFT
        xil_printf("Computing FFT...\r\n");
        fft(signal, SAMPLES_COUNT);

        // 3. Write to Shared Memory
        // Layout: R0, I0, R1, I1 ...
        for (int i = 0; i < SAMPLES_COUNT; i++) {
            bram_float_ptr[2*i]     = signal[i].real;
            bram_float_ptr[2*i + 1] = signal[i].imag;
        }
        
        xil_printf("Frame Done. Results in BRAM.\r\n");
    }

    cleanup_platform();
    return 0;
}
