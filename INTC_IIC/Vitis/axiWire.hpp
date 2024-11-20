/******************************************************************************
 *
 *
 * @file axiWire.h
 *
 * Header file for I2C related functions for PYNQ Microblaze, 
 * including the IIC read and write.
 *
 *
 * <pre>
 * MODIFICATION HISTORY:
 *
 * Ver   Who  Date     Changes
 * ----- --- ------- -----------------------------------------------
 * 1.00  yrq  release
 *
 * </pre>
 *
 *****************************************************************************/
#ifndef _AXI_WIRE_H_
#define _AXI_WIRE_H_

#include <xparameters.h>
#include "xiic.h"
#include "xiic_l.h"

class AxiWire {
public:
    AxiWire(unsigned int device){
            XIic_Initialize(&xi2c, device);
    }
    int read(unsigned int slave_address, unsigned char* buffer, unsigned int length){
        return XIic_Recv(xi2c.BaseAddress, slave_address, buffer, length, XIIC_STOP);
    }
    int write(unsigned int slave_address, unsigned char* buffer, unsigned int length){
        return XIic_Send(xi2c.BaseAddress, slave_address, buffer, length, XIIC_STOP);
    }
    void reset(){
        XIic_Reset(&xi2c);
    }
    void close(){
        XIic_ClearStats(&xi2c);
    }
    static unsigned int getNumDevices(){
        return XPAR_XIIC_NUM_INSTANCES;
    }

private:
    XIic xi2c;
};


#endif // _AXI_WIRE_H_
