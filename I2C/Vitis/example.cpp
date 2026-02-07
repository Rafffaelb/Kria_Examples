/***************************** Include Files *********************************/
	//#include<string>
#include <stdio.h>
#include <stdlib.h>
#include "ADXL345.h"
#include <sleep.h>


// Launch the serial port in setup
int main() {

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

		xil_printf("\033[2J");  // Clears the screen
    	xil_printf("\033[1A");  // Moves the cursor up three lines

		// Send integer and fractional parts using xil_printf
		xil_printf("AccelX: %d.%03d, AccelY: %d.%03d, AccelZ: %d.%03d\r\n",
				AccelX_int, AccelX_frac,
				AccelY_int, AccelY_frac,
				AccelZ_int, AccelZ_frac);

		usleep(200000);

	}
	return 0;
}
