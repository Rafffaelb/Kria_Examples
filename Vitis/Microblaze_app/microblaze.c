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

    float counter = 0;
    int data_to_write[6];

	// infinite loop
	while(1){

        float AccelX = counter * 0.004;
        float AccelY = counter * 0.004;
        float AccelZ = counter * 0.004;

        int AccelX_int = (int)AccelX;
        int AccelX_frac = abs((AccelX - (int)AccelX)*1000);
        int AccelY_int = (int)AccelY;
        int AccelY_frac = abs((AccelY - (int)AccelY)*1000);
        int AccelZ_int = (int)AccelZ;
        int AccelZ_frac = abs((AccelZ - (int)AccelZ)*1000);

        data_to_write[0] = AccelX_int;
        data_to_write[1] = AccelX_frac;

        data_to_write[2] = AccelY_int;
        data_to_write[3] = AccelY_frac;

        data_to_write[4] = AccelZ_int;
        data_to_write[5] = AccelZ_frac;
        

        // Write data to BRAM
        for (int i = 0; i < VECTOR_SIZE; i++) {
            u32 address = BRAM_BASE_ADDRESS + (i * 4); // Calculate address for each element
            Xil_Out32(address, data_to_write[i]);
        }

        counter += 1;

		usleep(20000);

	}
	return 0;
}
