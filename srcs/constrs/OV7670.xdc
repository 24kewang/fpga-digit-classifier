############################################################
## OV7670 CAMERA - PIN CONSTRAINTS FOR URBANA BOARD
## User-specified mapping
############################################################

## ----------------------
## CLOCKS & SYNC SIGNALS
## ----------------------

## ======================================================
## 100 MHz System Clock (Urbana Board Oscillator)
## ======================================================
set_property PACKAGE_PIN N15 [get_ports {Clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {Clk}]

## ======================================================
## Reset Button (BTN0) - active high
## ======================================================
set_property PACKAGE_PIN J2 [get_ports {reset_rtl_0}]
set_property IOSTANDARD LVCMOS25 [get_ports {reset_rtl_0}]

## ======================================================
## HDMI TMDS Clock
## ======================================================
set_property -dict { PACKAGE_PIN V17 IOSTANDARD TMDS_33 } [get_ports {hdmi_tmds_clk_n}]

set_property -dict { PACKAGE_PIN U16 IOSTANDARD TMDS_33 } [get_ports {hdmi_tmds_clk_p}]

## ======================================================
## HDMI TMDS Data Channels
## ======================================================

# Channel 0
set_property -dict { PACKAGE_PIN U18 IOSTANDARD TMDS_33 } [get_ports {hdmi_tmds_data_n[0]}]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD TMDS_33 } [get_ports {hdmi_tmds_data_p[0]}]

# Channel 1
set_property -dict { PACKAGE_PIN R17 IOSTANDARD TMDS_33 } [get_ports {hdmi_tmds_data_n[1]}]
set_property -dict { PACKAGE_PIN R16 IOSTANDARD TMDS_33 } [get_ports {hdmi_tmds_data_p[1]}]

# Channel 2
set_property -dict { PACKAGE_PIN T14 IOSTANDARD TMDS_33 } [get_ports {hdmi_tmds_data_n[2]}]
set_property -dict { PACKAGE_PIN R14 IOSTANDARD TMDS_33 } [get_ports {hdmi_tmds_data_p[2]}]


# XCLK (FPGA ? Camera)
set_property PACKAGE_PIN J13 [get_ports {cam_xclk}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_xclk}]

# PCLK (Camera ? FPGA)
set_property PACKAGE_PIN F14 [get_ports {cam_pclk}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_pclk}]

# HREF / HSYNC
set_property PACKAGE_PIN J14 [get_ports {cam_href}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_href}]

# VSYNC
set_property PACKAGE_PIN F15 [get_ports {cam_vsync}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_vsync}]


## ----------------------
## SCCB / I2C-LIKE BUS
## ----------------------

# SIOD (Data)
set_property PACKAGE_PIN E14 [get_ports {cam_siod}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_siod}]
set_property PULLUP true [get_ports {cam_siod}] ; # optional pull-up

# SIOC (Clock)
set_property PACKAGE_PIN H13 [get_ports {cam_sioc}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_sioc}]
set_property PULLUP true [get_ports {cam_sioc}] ; # optional pull-up

## ===============================
## Pin Assignment: LEDs/HEX Displays
## ===============================

set_property PACKAGE_PIN G6 [get_ports {hex_grid[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_grid[0]}]

set_property PACKAGE_PIN H6 [get_ports {hex_grid[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_grid[1]}]

set_property PACKAGE_PIN C3 [get_ports {hex_grid[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_grid[2]}]

set_property PACKAGE_PIN B3 [get_ports {hex_grid[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_grid[3]}]

set_property PACKAGE_PIN E6 [get_ports {hex_seg[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_seg[0]}]

set_property PACKAGE_PIN B4 [get_ports {hex_seg[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_seg[1]}]

set_property PACKAGE_PIN D5 [get_ports {hex_seg[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_seg[2]}]

set_property PACKAGE_PIN C5 [get_ports {hex_seg[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_seg[3]}]

set_property PACKAGE_PIN D7 [get_ports {hex_seg[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_seg[4]}]

set_property PACKAGE_PIN D6 [get_ports {hex_seg[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_seg[5]}]

set_property PACKAGE_PIN C4 [get_ports {hex_seg[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_seg[6]}]

set_property PACKAGE_PIN B5 [get_ports {hex_seg[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hex_seg[7]}]

## ----------------------
## PIXEL DATA BUS D0-D7
## ----------------------

# D0
set_property PACKAGE_PIN J16 [get_ports {cam_d[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[0]}]

# D1
set_property PACKAGE_PIN J15 [get_ports {cam_d[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[1]}]

# D2
set_property PACKAGE_PIN K16 [get_ports {cam_d[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[2]}]

# D3
set_property PACKAGE_PIN K14 [get_ports {cam_d[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[3]}]

# D4
set_property PACKAGE_PIN H17 [get_ports {cam_d[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[4]}]

# D5
set_property PACKAGE_PIN G18 [get_ports {cam_d[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[5]}]

# D6
set_property PACKAGE_PIN H16 [get_ports {cam_d[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[6]}]

# D7
set_property PACKAGE_PIN H18 [get_ports {cam_d[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_d[7]}]
