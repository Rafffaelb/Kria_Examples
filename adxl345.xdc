
# Kria KR260 Constraints for ADXL345 (PMOD)
# ==========================================
# Assuming connection to PMOD 1 (Right Angle connector, Top Row)

# PMOD 1 Pin 3 (SCL)
set_property PACKAGE_PIN H12 [get_ports adxl345_iic_scl_io]
set_property IOSTANDARD LVCMOS33 [get_ports adxl345_iic_scl_io]
set_property PULLUP true [get_ports adxl345_iic_scl_io]

# PMOD 1 Pin 4 (SDA)
set_property PACKAGE_PIN E10 [get_ports adxl345_iic_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports adxl345_iic_sda_io]
set_property PULLUP true [get_ports adxl345_iic_sda_io]
