`timescale 1ns / 1ps

module ov7670_capture #(
    parameter int IMG_WIDTH  = 640,
    parameter int IMG_HEIGHT = 480
)(
    input  logic        pclk,
    input  logic        reset,
    input  logic        vsync,
    input  logic        href,
    input  logic [7:0]  data,

    output logic [18:0] bram_addr,   // 640*480 < 2^19
    output logic [5:0]  bram_din,    // RGB222 = 6 bits
    output logic        bram_we
);

    logic [18:0] addr = 0;
    logic        byte_phase = 0;
    logic [15:0] pixel565;
    logic [4:0] r, b;
    logic [5:0] g;
    logic [10:0] weighted_sum;
    
    assign r = pixel565[15:11];  // Red: 5 bits
    assign g = pixel565[10:5];   // Green: 6 bits
    assign b = pixel565[4:0];    // Blue: 5 bits
    assign weighted_sum = (r * 5'd19) + (g * 6'd37) + (b * 5'd7);

    always_ff @(posedge pclk or posedge reset) begin
        if (reset) begin
            addr       <= 0;
            bram_we    <= 0;
            byte_phase <= 0;
        end else begin
            bram_we <= 0;   // default

            if (vsync) begin
                addr       <= 0;   // restart frame
                byte_phase <= 0;
            end
            else if (href) begin
                byte_phase <= ~byte_phase;

                if (!byte_phase)
                    pixel565[15:8] <= data;    // high byte first
                else begin
                    pixel565[7:0] <= data;     // low byte completes pixel
                
                    bram_din  <= weighted_sum[10:5];  // Divide by 64 (right shift 6)
                    
//                    bram_din <= {
//                        pixel565[15:14],   // R[4:2]
//                        pixel565[10:9],    // G[5:3]
//                        pixel565[4:3]      // B[4:2]
//                    };

                    bram_addr <= addr;
                    bram_we   <= 1;
                    addr      <= addr + 1;
                end
            end
        end
    end
endmodule
