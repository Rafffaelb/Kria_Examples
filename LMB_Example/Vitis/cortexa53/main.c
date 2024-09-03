/***************************** Include Files *********************************/
	//#include<string>
#include <stdio.h>
#include <stdlib.h>
#include <sleep.h>
#include "xparameters.h"

#define VECTOR_SIZE 6
#define BRAM_BASE_ADDRESS XPAR_AXI_BRAM_0_BASEADDRESS


// Launch the serial port in setup
int main() {

    int read_data[6];

    while(1){

        // Read data from BRAM
        for (int i = 0; i < VECTOR_SIZE; i++) {
            u32 address = BRAM_BASE_ADDRESS + (i * 4); // Calculate address for each element
            read_data[i] = Xil_In32(address);
        }

		xil_printf("\033[2J");  // Clears the screen
    	xil_printf("\033[1A");  // Moves the cursor up three lines

		// Send integer and fractional parts using xil_printf
		xil_printf("AccelX: %d.%03d, AccelY: %d.%03d, AccelZ: %d.%03d\r\n",
				read_data[0], read_data[1],
				read_data[2], read_data[3],
				read_data[4], read_data[5]);

		usleep(20000);

	}
	return 0;
}