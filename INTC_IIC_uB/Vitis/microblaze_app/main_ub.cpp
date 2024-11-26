/***************************** Include Files *********************************/
	//#include<string>
#include <stdio.h>
#include <stdlib.h>
#include <sleep.h>
#include "ADXL345.h"
#include "xparameters.h"

#define VECTOR_SIZE 6
#define BRAM_BASE_ADDRESS XPAR_AXI_BRAM_0_BASEADDRESS


// Launch the serial port in setup
int main() {

    int data_to_write[VECTOR_SIZE];

    Vector vetor;

	// initiallize i2c
	AxiWire i2cDevice(0); // Initialize an AxiWire object for device 0
	// initialize mpu
	ADXL345 mpu;
	if(mpu.begin(&i2cDevice)){
		xil_printf("initialization failed");
  	}else{
  		xil_printf("initialization successful!");
	}

	// infinite loop
	while(1){

        vetor = mpu.readScaled();

        int AccelX_int = (int)vetor.XAxis;
        int AccelX_frac = abs((vetor.XAxis - (int)vetor.XAxis)*1000);
        int AccelY_int = (int)vetor.YAxis;
        int AccelY_frac = abs((vetor.YAxis - (int)vetor.YAxis)*1000);
        int AccelZ_int = (int)vetor.ZAxis;
        int AccelZ_frac = abs((vetor.ZAxis - (int)vetor.ZAxis)*1000);

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

		// usleep(20000);

	}
	return 0;
}