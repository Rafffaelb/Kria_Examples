/*
ADXL345.cpp - Class file for the ADXL345 Triple Axis Accelerometer Arduino Library.

Version: 1.1.0
(c) 2014 Korneliusz Jarzebski
www.jarzebski.pl

This program is free software: you can redistribute it and/or modify
it under the terms of the version 3 GNU General Public License as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "ADXL345.h"

int constrain(int value, int minVal, int maxVal) {
    if (value < minVal) {
        return minVal;
    } else if (value > maxVal) {
        return maxVal;
    } else {
        return value;
    }
}

bool ADXL345::begin(AxiWire *axiWire_handler)
{
    f.XAxis = 0;
    f.YAxis = 0;
    f.ZAxis = 0;

    Wire = axiWire_handler;

    // Check ADXL345 REG DEVID
    if (fastRegister8(ADXL345_REG_DEVID) != 0xE5)
    {
        return false;
    }

    // Enable measurement mode (0b00001000)
    writeRegister8(ADXL345_REG_POWER_CTL, 0x08);

    clearSettings();

    return true;
}

// Set Range
void ADXL345::setRange(adxl345_range_t range)
{
  // Get actual value register
  uint8_t value = readRegister8(ADXL345_REG_DATA_FORMAT);

  // Update the data rate
  // (&) 0b11110000 (0xF0 - Leave HSB)
  // (|) 0b0000xx?? (range - Set range)
  // (|) 0b00001000 (0x08 - Set Full Res)
  value &= 0xF0;
  value |= range;
  value |= 0x08;

  writeRegister8(ADXL345_REG_DATA_FORMAT, value);
}

// Get Range
adxl345_range_t ADXL345::getRange(void)
{
    return (adxl345_range_t)(readRegister8(ADXL345_REG_DATA_FORMAT) & 0x03);
}

// Set Data Rate
void ADXL345::setDataRate(adxl345_dataRate_t dataRate)
{
    writeRegister8(ADXL345_REG_BW_RATE, dataRate);
}

// Get Data Rate
adxl345_dataRate_t ADXL345::getDataRate(void)
{
    return (adxl345_dataRate_t)(readRegister8(ADXL345_REG_BW_RATE) & 0x0F);
}

// Low Pass Filter
Vector ADXL345::lowPassFilter(Vector vector, float alpha)
{
    f.XAxis = vector.XAxis * alpha + (f.XAxis * (1.0 - alpha));
    f.YAxis = vector.YAxis * alpha + (f.YAxis * (1.0 - alpha));
    f.ZAxis = vector.ZAxis * alpha + (f.ZAxis * (1.0 - alpha));
    return f;
}

// Read raw values
Vectori ADXL345::readRaw(void)
{
    r.XAxis = readRegister16(ADXL345_REG_DATAX0);
    r.YAxis = readRegister16(ADXL345_REG_DATAY0);
    r.ZAxis = readRegister16(ADXL345_REG_DATAZ0);
    return r;
}

// Read normalized values
Vector ADXL345::readNormalize(float gravityFactor)
{
    readRaw();

    // (4 mg/LSB scale factor in Full Res) * gravity factor
    n.XAxis = r.XAxis * 0.004 * gravityFactor;
    n.YAxis = r.YAxis * 0.004 * gravityFactor;
    n.ZAxis = r.ZAxis * 0.004 * gravityFactor;

    return n;
}

// Read scaled values
Vector ADXL345::readScaled(void)
{
    readRaw();

    // (4 mg/LSB scale factor in Full Res)
    n.XAxis = r.XAxis * 0.004;
    n.YAxis = r.YAxis * 0.004;
    n.ZAxis = r.ZAxis * 0.004;

    return n;
}

void ADXL345::clearSettings(void)
{
    setRange(ADXL345_RANGE_2G);
    setDataRate(ADXL345_DATARATE_100HZ);

    writeRegister8(ADXL345_REG_THRESH_TAP, 0x00);
    writeRegister8(ADXL345_REG_DUR, 0x00);
    writeRegister8(ADXL345_REG_LATENT, 0x00);
    writeRegister8(ADXL345_REG_WINDOW, 0x00);
    writeRegister8(ADXL345_REG_THRESH_ACT, 0x00);
    writeRegister8(ADXL345_REG_THRESH_INACT, 0x00);
    writeRegister8(ADXL345_REG_TIME_INACT, 0x00);
    writeRegister8(ADXL345_REG_THRESH_FF, 0x00);
    writeRegister8(ADXL345_REG_TIME_FF, 0x00);

    uint8_t value;

    value = readRegister8(ADXL345_REG_ACT_INACT_CTL);
    value &= 0b10001000;
    writeRegister8(ADXL345_REG_ACT_INACT_CTL, value);

    value = readRegister8(ADXL345_REG_TAP_AXES);
    value &= 0b11111000;
    writeRegister8(ADXL345_REG_TAP_AXES, value);
}

// Write byte to register
void ADXL345::writeRegister8(uint8_t reg, uint8_t value)
{
    // Wire.beginTransmission(ADXL345_ADDRESS);
    // Wire.write(reg);
    // Wire.write(value);    
    // Wire.endTransmission();
    
    uint8_t send_buffer[2] = {reg, value};
	unsigned int written_bytes = Wire->write(ADXL345_ADDRESS, send_buffer, 2);
}

// Read byte to register
uint8_t ADXL345::fastRegister8(uint8_t reg)
{
    uint8_t value[1]; // value;
    // Wire.beginTransmission(ADXL345_ADDRESS);
    // Wire.write(reg);
    // Wire.endTransmission();
    uint8_t send_buffer[1];
	send_buffer[0] = reg;
	unsigned int written_bytes = Wire->write(ADXL345_ADDRESS, send_buffer, 1);
    
    // Wire.requestFrom(ADXL345_ADDRESS, 1);
    // value = Wire.read();
    // Wire.endTransmission();
	unsigned int read_bytes = Wire->read(ADXL345_ADDRESS, value, 1);

    return value[0];
}

// Read byte from register
uint8_t ADXL345::readRegister8(uint8_t reg)
{
    uint8_t value[1];
    // Wire.beginTransmission(ADXL345_ADDRESS);
    // Wire.write(reg);
    // Wire.endTransmission();
    uint8_t send_buffer[1];
	send_buffer[0] = reg;
	unsigned int written_bytes = Wire->write(ADXL345_ADDRESS, send_buffer, 1);

    // Wire.beginTransmission(ADXL345_ADDRESS);
    // Wire.requestFrom(ADXL345_ADDRESS, 1);
    // while(!Wire.available()) {};
    // value = Wire.read();
    // Wire.endTransmission();
    unsigned int read_bytes = Wire->read(ADXL345_ADDRESS, value, 1);

    return value[0];
}

// Read word from register
int16_t ADXL345::readRegister16(uint8_t reg)
{
    int16_t value;
    // Wire.beginTransmission(ADXL345_ADDRESS);
    // Wire.write(reg);
    // Wire.endTransmission();
    uint8_t va[2];
    uint8_t send_buffer[1];
	send_buffer[0] = reg;
	unsigned int written_bytes = Wire->write(ADXL345_ADDRESS, send_buffer, 1);

    // Wire.beginTransmission(ADXL345_ADDRESS);
    // Wire.requestFrom(ADXL345_ADDRESS, 2);
    // while(!Wire.available()) {};
    // uint8_t vla = Wire.read();
    // uint8_t vha = Wire.read();
    // Wire.endTransmission();
    unsigned int read_bytes = Wire->read(ADXL345_ADDRESS, va, 2);


    value = va[0] << 8 | va[1];

    return value;
}

void ADXL345::readADXL345(int16_t *x, int16_t *y, int16_t *z) {
    *x = readRegister16(ADXL345_REG_DATAX0);
    *y = readRegister16(ADXL345_REG_DATAX0 + 2);
    *z = readRegister16(ADXL345_REG_DATAX0 + 4);
}

void ADXL345::writeRegisterBit(uint8_t reg, uint8_t pos, bool state)
{
    uint8_t value;
    value = readRegister8(reg);

    if (state)
    {
	value |= (1 << pos);
    } else 
    {
	value &= ~(1 << pos);
    }

    writeRegister8(reg, value);
}

bool ADXL345::readRegisterBit(uint8_t reg, uint8_t pos)
{
    uint8_t value;
    value = readRegister8(reg);
    return ((value >> pos) & 1);
}