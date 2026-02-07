#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xintc_l.h"
#include <xil_exception.h>
#include <xil_types.h>
#include "xil_printf.h"
#include <sleep.h>

#define INTC_BASEADDR		XPAR_XINTC_0_BASEADDR
#define INTC_DEVICE_INTR_ID	0x0U
#define INTC_DEVICE_INT_MASK	0x1U
#define VECTOR_SIZE 6
#define BRAM_BASE_ADDRESS XPAR_AXI_BRAM_0_BASEADDRESS

void DeviceDriverHandler(void *CallbackRef);
void Rafael_ExceptionHandler(void *Data);

volatile static int InterruptProcessed = FALSE;
void *callback_ref = NULL;

int main(void)
{

    XIntc_RegisterHandler((u32) INTC_BASEADDR, INTC_DEVICE_INTR_ID,
		      (XInterruptHandler)DeviceDriverHandler,
		      (void *)0);
    XIntc_EnableIntr((u32) INTC_BASEADDR, INTC_DEVICE_INT_MASK);
    XIntc_Out32((u32) INTC_BASEADDR + XIN_MER_OFFSET, XIN_INT_MASTER_ENABLE_MASK);

    void* ptr = (void*)(u32)INTC_BASEADDR;
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				     (Xil_ExceptionHandler)XIntc_DeviceInterruptHandler,
				     ptr);
    Xil_ExceptionEnable();
    XIntc_Out32(INTC_BASEADDR + XIN_ISR_OFFSET, INTC_DEVICE_INT_MASK);

    int counter = 1;

    void* Data;

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)Rafael_ExceptionHandler, callback_ref);

    Xil_ExceptionEnable();

	while (1) {
		/*
		 * If the interrupt occurred which is indicated by the global
		 * variable which is set in the device driver handler, then
		 * stop waiting.
		 */

        if (counter % 100 == 0){
            // InterruptProcessed = !InterruptProcessed;
            // DeviceDriverHandler(callback_ref);
            // xil_printf("Bool value: %d\r\n", InterruptProcessed);
            Rafael_ExceptionHandler(Data);
        }

        counter++;
        usleep(20000);

        if (counter == 1000) {
            break; // Return successful exit
        }
	}

    xil_printf("Successfully ran Example\r\n");
	return XST_SUCCESS;

}

void Rafael_ExceptionHandler(void *Data)
{

    callback_ref = Data;

    // Your exception handler logic here
    // For example, print or handle the exception.
    xil_printf("Exception occurred! Handling...\n");

    InterruptProcessed = !InterruptProcessed;

    // If you need to call the DeviceDriverHandler function within the handler
    DeviceDriverHandler(callback_ref);
}

void DeviceDriverHandler(void *CallbackRef)
{
	/*
	 * Indicate the interrupt has been processed using a shared variable.
	 */
    int read_data[VECTOR_SIZE];
    // Read data from BRAM
       for (int i = 0; i < VECTOR_SIZE; i++) {
        u32 address = BRAM_BASE_ADDRESS + (i * 4); // Calculate address for each element
        read_data[i] = Xil_In32(address);
    }

	// xil_printf("\033[2J");  // Clears the screen
	xil_printf("\033[1A");  // Moves the cursor up three lines

	// Send integer and fractional parts using xil_printf
	xil_printf("AccelX: %d.%03d, AccelY: %d.%03d, AccelZ: %d.%03d\r\n",
			read_data[0], read_data[1],
			read_data[2], read_data[3],
			read_data[4], read_data[5]);
}