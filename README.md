# FPGA-Accelerated Real-Time Number Classification

**Authors:** Vikram Rao and Kevin Wang  
**Course:** ECE 385 Fall 2025  
**Lab Section:** AB1  
**TA:** Xuanbo (Bob) Jin

## Overview

This project implements a real-time digit classifier on an FPGA using an OV7670 camera and a 2-layer neural network with pre-trained weights. The system captures live video, processes a central region of the frame, and classifies handwritten digits (0-9) using a neural network trained on the MNIST dataset.

### Key Features

- **Real-time camera input** from OV7670 camera module
- **Live HDMI output** displaying the camera feed with grayscale filter and red box overlay
- **Hardware-accelerated neural network** inference on FPGA
- **2-layer neural network** with ReLU activation function
- **88% classification accuracy** on MNIST-style digits
- **Prediction displayed** on hex drivers

## System Architecture

### Camera Pipeline

1. **Camera Configuration**: OV7670 initialized via SCCB protocol using register values from ROM
2. **Pixel Capture**: RGB565 pixel data captured and synchronized using PCLK, HREF, and VSYNC signals
3. **Grayscale Conversion**: RGB565 converted to 6-bit grayscale
4. **Downsampling**: 4×4 averaging downsampler reduces resolution to 28×28 (MNIST compatible)
5. **HDMI Display**: Processed feed displayed with overlay showing classification region

### Neural Network

The neural network performs forward propagation using pre-trained weights from a model trained on the MNIST dataset:

- **Input**: 28×28 grayscale image (784 pixels, normalized 0-1)
- **Layer 1**: 784×10 weight matrix (W1) with 10×1 bias (b1), ReLU activation
- **Layer 2**: 10×10 weight matrix (W2) with 10×1 bias (b2)
- **Output**: 10-element probability vector (argmax gives predicted digit)
- **Number Representation**: Q16.16 fixed-point arithmetic for all computations

The weights were trained using gradient descent with backpropagation (1500 iterations, learning rate α=0.1).

## Hardware Requirements

- FPGA development board (with Vivado support)
- OV7670 camera module
- HDMI-compatible monitor
- 5kΩ pull-up resistors for SCCB lines (cam_sioc, cam_siod)

## Camera Connections

### Clock and Synchronization
- **XCLK**: Master clock from FPGA to camera
- **PCLK**: Pixel clock from camera to FPGA
- **VSYNC**: Frame synchronization signal
- **HREF**: Horizontal line valid signal

### SCCB Configuration Interface
- **cam_sioc**: SCCB clock line
- **cam_siod**: SCCB bidirectional data line (requires 5kΩ pull-up)

### Pixel Data
- **cam_d[7:0]**: 8-bit parallel pixel data bus

## Module Descriptions

### Camera Modules

- **camera_top.sv**: Top-level controller integrating all camera subsystems
- **ov7670_config_rom.sv**: ROM containing OV7670 register configuration sequence
- **ov7670_sccb_config.sv**: High-level SCCB sequencing for camera initialization
- **SCCB_interface.sv**: Low-level SCCB protocol implementation (start/stop conditions, bit-level communication)
- **ov7670_capture.sv**: Captures RGB565 pixel data and converts to 6-bit grayscale
- **downsample_2x2_avg.sv**: Reduces resolution via 2×2 block averaging to create 28×28 output
- **VGA_controller.sv**: Generates 640×480 VGA timing signals for HDMI output

### Neural Network Module

- **digit_cnn.sv**: Core neural network implementation performing matrix multiplications and ReLU activation

## File Structure

```
.
├── README.md
├── srcs/
│   ├── constrs/
│   │   └── OV7670.xdc
│   ├── sim/
│   │   └── camera_top_tb.sv
│   └── sources/
│       ├── camera_top.sv
│       ├── ov7670_config_rom.sv
│       ├── ov7670_sccb_config.sv
│       ├── SCCB_interface.sv
│       ├── ov7670_capture.sv
│       ├── downsample_2x2_avg.sv
│       |── VGA_controller.sv
│       |── digit_cnn.sv
│       └── HexDriver.sv
├── scripts/
│   ├── csv_to_rom.py
│   └── test_nn.py
└── weights/
    ├── b1.coe
    ├── b2.coe
    ├── W1.coe
    └── W2.coe
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone [repository-url]
cd [repository-name]
```

### 2. Generate Weight Files



### 3. Vivado Project Setup

1. Create a new Vivado project
2. Add all SystemVerilog source files from `src/` directory
3. Import constraint files from `constraints/` directory
4. Add generated .coe files to Block Memory Generator IP cores
5. Configure Block Memory Generator for:
   - W1 weights (10×784 matrix)
   - W2 weights (10×10 matrix)
   - b1 bias (10×1 vector)
   - b2 bias (10×1 vector)

### 4. Hardware Connections

Connect the OV7670 camera to your FPGA according to the pin assignments in your constraints file. Ensure 5kΩ pull-up resistors are connected to the SCCB lines.

### 5. Synthesis and Implementation

1. Run synthesis in Vivado
2. Run implementation
3. Generate bitstream
4. Program the FPGA

## Usage

1. Power on the FPGA with the camera connected
2. The camera will automatically initialize via SCCB
3. View the live camera feed on the HDMI monitor
4. Hold a handwritten digit (0-9) in front of the camera within the red box overlay
5. The predicted digit will appear on the hex display

## Design Statistics

| Resource | Usage |
|----------|-------|
| LUT | 11,001 |
| DSP | 7 |
| BRAM | 66 |
| Flip-Flop | 25,929 |
| Frequency | 42.39 MHz (VGA: 25 MHz, WNS 16.411ns) |
| Static Power | 0.078 W |
| Dynamic Power | 0.322 W |
| Total Power | 0.4 W |

## Testing and Verification

Testbenches were created to verify neural network functionality using MNIST training data converted to 6-bit pixel arrays. Test cases confirmed correct predictions by matching outputs with labeled data.

## Future Improvements

- Add additional neural network layers to improve accuracy beyond 88%
- Explore alternative model architectures optimized for hardware implementation
- Implement dynamic retraining or transfer learning capabilities

## Acknowledgments

- OV7670 camera interface based on work by wbraun: [OV7670-Verilog](https://github.com/westonb/OV7670-Verilog)
- Neural network model inspired by Samson Zhang's [MNIST tutorial](https://www.kaggle.com/code/wwsalmon/simple-mnist-nn-from-scratch-numpy-no-tf-keras/notebook) and [YouTube explanation](https://www.youtube.com/watch?v=w8yWXqWQYmU)

## References

1. W. Braun, "OV7670-Verilog," GitHub repository. Available: https://github.com/westonb/OV7670-Verilog
2. Samson Zhang, "Simple MNIST NN from scratch (numpy, no TF/Keras)," Kaggle, Nov. 2020. Available: https://www.kaggle.com/code/wwsalmon/simple-mnist-nn-from-scratch-numpy-no-tf-keras/notebook
3. Samson Zhang, "Building a neural network FROM SCRATCH," YouTube, Nov. 24, 2020. Available: https://www.youtube.com/watch?v=w8yWXqWQYmU