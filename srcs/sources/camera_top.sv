`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/17/2025 09:09:13 PM
// Design Name: 
// Module Name: camera_topS
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module camera_top(
    input  logic Clk,           // 100 MHz board clock
    input  logic reset_rtl_0,   // active high reset

    // --- OV7670 Camera Interface ---
    output logic cam_xclk,      // clock to camera (~24-25 MHz)
    output logic cam_sioc,      // SCCB / I2C clock
    inout  logic cam_siod,      // SCCB / I2C data
    input  logic cam_pclk,      // pixel clock from camera
    input  logic cam_vsync,     // frame sync
    input  logic cam_href,      // line valid
    input  logic [7:0] cam_d,   // pixel bus D0-D7

    // --- HDMI OUTPUT ---
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0] hdmi_tmds_data_n,
    output logic [2:0] hdmi_tmds_data_p,
    
    output logic [7:0] hex_seg,
    output logic [3:0] hex_grid
    );
    
    
    logic clk_25MHz, clk_125MHz;
    logic locked;
    logic hsync, vsync, vde;
    //logic [1:0] red, green, blue;
    logic [5:0] grayscale;
    logic reset_ah;
    logic [9:0] drawX, drawY;
    
    assign reset_ah = reset_rtl_0;
    
    localparam IMG_WIDTH  = 640;
    localparam IMG_HEIGHT = 480;
    
    logic [18:0] bram_addr_write;   // enough for 640*480 = 307200 < 2^19
    logic [5:0]  bram_din;
    logic        bram_we;
    
    logic [18:0] bram_addr_read;
    logic [5:0]  bram_dout;
    
    localparam BOX_WIDTH  = 56;
    localparam BOX_HEIGHT = 56;
    localparam logic [9:0] BOX_X = (IMG_WIDTH - BOX_WIDTH) / 2;   // Center horizontally
    localparam logic [9:0] BOX_Y = (IMG_HEIGHT - BOX_HEIGHT) / 2; // Center vertically
    
    assign grayscale = bram_dout;
    
    // Add box overlay logic here
    logic in_box;
    logic is_box_border;
    logic [9:0] ds_index;
    
    logic [5:0] cnn_out [0:783];
    logic [5:0] cnn_latched [0:783];
    
    logic frame_done;
    
    always_comb begin
        // Check if current pixel is within box region
        in_box = (drawX >= BOX_X && drawX < (BOX_X + BOX_WIDTH) &&
                  drawY >= BOX_Y && drawY < (BOX_Y + BOX_HEIGHT));
        
        // Check if on the border (1 pixel thick)
        is_box_border = in_box && 
                        (drawX == BOX_X || drawX == (BOX_X + BOX_WIDTH - 1) ||
                         drawY == BOX_Y || drawY == (BOX_Y + BOX_HEIGHT - 1));
                         
        if (in_box) begin
            ds_index = ((drawY - BOX_Y) >> 1) * 28 +
                   ((drawX - BOX_X) >> 1);
        end else begin
            ds_index = 0;
        end
    end
    
    // Output with overlay
    logic [5:0] red_out, green_out, blue_out;
    
    always_comb begin
        if (is_box_border && vde) begin
            // Red border: full red, no green/blue
            red_out   = 6'b111111;
            green_out = 6'b000000;
            blue_out  = 6'b000000;
        end else if (in_box && vde) begin
            // Show downsampled pixel stretched 4x4
            red_out   = cnn_out[ds_index];
            green_out = cnn_out[ds_index];
            blue_out  = cnn_out[ds_index];
        end else begin
            // Normal grayscale
            red_out   = grayscale;
            green_out = grayscale;
            blue_out  = grayscale;
        end
    end
    
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    assign cam_xclk = clk_25MHz;
    
    logic [7:0] rom_addr;
    logic [15:0] rom_data;
    logic [7:0] sccb_addr, sccb_data;
    logic       sccb_start, sccb_ready;
    
    logic sioc_oe;
    logic siod_oe;
    assign cam_sioc  = sioc_oe ? 1'b0 : 1'bZ;
    assign cam_siod  = siod_oe ? 1'b0 : 1'bZ;
    
    ov7670_config_rom rom1(
        .clk(Clk),
        .addr(rom_addr),
        .data(rom_data)
        );
    
    ov7670_sccb_config sccb_cfg (
        .clk(Clk),       
        .reset(reset_ah),
        .rom_data(rom_data),
        .rom_addr(rom_addr),
        .sccb_ready(sccb_ready),
        .sccb_addr(sccb_addr),
        .sccb_data(sccb_data),
        .sccb_start(sccb_start),
        .done()            // optional status, ignore for now
    );
    
    ov7670_capture #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) capture_inst (
        .pclk(cam_pclk),
        .reset(reset_ah),
        .vsync(cam_vsync),
        .href(cam_href),
        .data(cam_d),

        .bram_addr(bram_addr_write),
        .bram_din(bram_din),
        .bram_we(bram_we)
    );
    
    SCCB_interface i2c(
    .clk(Clk),
    .reset(reset_ah),
    .start(sccb_start),
    .address(sccb_addr),
    .data(sccb_data),
    .ready(sccb_ready),
    .SIOC_oe(sioc_oe),
    .SIOD_oe(siod_oe)
    );

    
    
    blk_mem_gen_0 vram_bram (
    // AXI port (A)
    .clka(cam_pclk),
    .ena(1'b1),
    .wea(bram_we),                  
    .addra(bram_addr_write),         
    .dina(bram_din),              

    // Video port (B)
    .clkb(clk_25MHz),
    .enb(1'b1),
    .addrb(bram_addr_read),             
    .doutb(bram_dout)               
);
    
   vga_controller vga (
    .pixel_clk(clk_25MHz),
    .reset(reset_ah),
    .hs(hsync),
    .vs(vsync),
    .active_nblank(vde),
    .drawX(drawX),
    .drawY(drawY)
);

always_comb begin
        if (vde && drawX < IMG_WIDTH && drawY < IMG_HEIGHT)
            bram_addr_read = drawY * IMG_WIDTH + drawX;
        else
            bram_addr_read = 19'd0;
    end
   
//assign red   = bram_dout[5:4];
//assign green = bram_dout[3:2];
//assign blue  = bram_dout[1:0];
logic [3:0] digit;
logic valid;
digit_cnn cnn(
    .clk(Clk),
    .rst(reset_rtl_0),
    .start(cnn_start),
    .pixels(cnn_latched),  // 784 pixels, 6-bit grayscale
    .digit(digit),           // 0-9 prediction
    .valid(valid)
);
logic inference_started;
logic cnn_start;

always_ff @(posedge Clk) begin
    if (reset_rtl_0) begin
        inference_started <= 1'b0;
        cnn_start         <= 1'b0;
    end else begin
        cnn_start <= 1'b0;  // default

        if (frame_done && !inference_started) begin
            for (int i = 0; i < 784; i++) begin
                cnn_latched[i] <= cnn_out[i];
            end
            inference_started <= 1'b1;
            cnn_start <= 1'b1; // ONE-CYCLE PULSE
        end
        else if (valid) begin
            inference_started <= 1'b0;
        end
    end
end

//logic [3:0] debug;
logic [3:0] digit_out;
always_ff @ (posedge Clk) begin
    if (valid) begin
        digit_out <= digit;
    end
end
        

HexDriver hex_driver(
    .clk(Clk),
    .reset(reset_rtl_0),

//    .in({{2'b0, cnn_out[0][5:4]}, cnn_out[0][3:0], digit, digit_out}),
    .in({4'b0, 4'b0, 4'b0, digit_out}),
    .hex_seg(hex_seg),
    .hex_grid(hex_grid)
);


downsample_2x2_avg downsample (
    .clk(clk_25MHz),
    .reset(reset_ah),
    .vde(vde),
    .drawX(drawX),
    .drawY(drawY),
    .pixel_in(grayscale),
    .BOX_X(BOX_X),
    .BOX_Y(BOX_Y),
    .cnn_out(cnn_out),
    .frame_done(frame_done)
);

hdmi_tx_0 vga_to_hdmi (
    //Clocking and Reset
    .pix_clk(clk_25MHz),
    .pix_clkx5(clk_125MHz),
    .pix_clk_locked(locked),
    .rst(reset_ah),
    //Color and Sync Signals
    .red(red_out),
    .green(green_out),
    .blue(blue_out),
    .hsync(hsync),
    .vsync(vsync),
    .vde(vde),
    
    //aux Data (unused)
    .aux0_din(4'b0),
    .aux1_din(4'b0),
    .aux2_din(4'b0),
    .ade(1'b0),
    
    //Differential outputs
    .TMDS_CLK_P(hdmi_tmds_clk_p),          
    .TMDS_CLK_N(hdmi_tmds_clk_n),          
    .TMDS_DATA_P(hdmi_tmds_data_p),         
    .TMDS_DATA_N(hdmi_tmds_data_n)          
);
    
    
endmodule
