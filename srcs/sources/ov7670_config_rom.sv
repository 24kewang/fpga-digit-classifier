`timescale 1ns / 1ps

module ov7670_config_rom(
    input  logic clk,
    input  logic [7:0] addr,
    output logic [15:0] data
);
    // FFFF = end of ROM
    // FFF0 = delay entry (10 ms)
    always_ff @(posedge clk) begin
        unique case (addr)
            8'd0:  data <= 16'h1280; // COM7 reset
            8'd1:  data <= 16'hFFF0; // delay
            8'd2:  data <= 16'h1204; // COM7 - RGB output
            8'd3:  data <= 16'h1180; // CLKRC
            8'd4:  data <= 16'h0C00; // COM3
            8'd5:  data <= 16'h3E00; // COM14
            8'd6:  data <= 16'h0400; // COM1
            8'd7:  data <= 16'h40D0; // COM15 RGB565, full range
            8'd8:  data <= 16'h3A04; // TSLB
            8'd9:  data <= 16'h1418; // COM9
            8'd10: data <= 16'h4FB3; // MTX1
            8'd11: data <= 16'h50B3; // MTX2
            8'd12: data <= 16'h5100; // MTX3
            8'd13: data <= 16'h523D; // MTX4
            8'd14: data <= 16'h53A7; // MTX5
            8'd15: data <= 16'h54E4; // MTX6
            8'd16: data <= 16'h589E; // MTXS
            8'd17: data <= 16'h3DC0; // COM13
            8'd18: data <= 16'h1714; // HSTART
            8'd19: data <= 16'h1802; // HSTOP
            8'd20: data <= 16'h3280; // HREF
            8'd21: data <= 16'h1903; // VSTART
            8'd22: data <= 16'h1A7B; // VSTOP
            8'd23: data <= 16'h030A; // VREF
            8'd24: data <= 16'h0F41; // COM6
            8'd25: data <= 16'h1E00; // MVFP
            8'd26: data <= 16'h330B; // CHLF
            8'd27: data <= 16'h3C78; // COM12
            8'd28: data <= 16'h6900; // GFIX
            8'd29: data <= 16'h7400; // REG74
            8'd30: data <= 16'hB084; // magic color
            8'd31: data <= 16'hB10C; // ABLC1
            8'd32: data <= 16'hB20E; // magic
            8'd33: data <= 16'hB380; // THL_ST

            // mystery scaling
            8'd34: data <= 16'h703A;
            8'd35: data <= 16'h7135;
            8'd36: data <= 16'h7211;
            8'd37: data <= 16'h73F0;
            8'd38: data <= 16'hA202;

            // gamma curve
            8'd39: data <= 16'h7A20;
            8'd40: data <= 16'h7B10;
            8'd41: data <= 16'h7C1E;
            8'd42: data <= 16'h7D35;
            8'd43: data <= 16'h7E5A;
            8'd44: data <= 16'h7F69;
            8'd45: data <= 16'h8076;
            8'd46: data <= 16'h8180;
            8'd47: data <= 16'h8288;
            8'd48: data <= 16'h838F;
            8'd49: data <= 16'h8496;
            8'd50: data <= 16'h85A3;
            8'd51: data <= 16'h86AF;
            8'd52: data <= 16'h87C4;
            8'd53: data <= 16'h88D7;
            8'd54: data <= 16'h89E8; // last gamma entry

            // AGC / AEC block
            8'd55: data <= 16'h13E0; // COM8, disable AGC/AEC
            8'd56: data <= 16'h0000; // gain = 0
            8'd57: data <= 16'h1000; // ARCJ = 0
            8'd58: data <= 16'h0D40; // COM4 magic
            8'd59: data <= 16'h1418; // COM9
            8'd60: data <= 16'hA505; // BD50MAX
            8'd61: data <= 16'hAB07; // BD60MAX
            8'd62: data <= 16'h2495; // AGC upper limit
            8'd63: data <= 16'h2533; // AGC lower limit
            8'd64: data <= 16'h26E3; // fast mode region
            8'd65: data <= 16'h9F78; // HAECC1
            8'd66: data <= 16'hA068; // HAECC2
            8'd67: data <= 16'hA103; // magic
            8'd68: data <= 16'hA6D8; // HAECC3
            8'd69: data <= 16'hA7D8; // HAECC4
            8'd70: data <= 16'hA8F0; // HAECC5
            8'd71: data <= 16'hA990; // HAECC6
            8'd72: data <= 16'hAA94; // HAECC7
            8'd73: data <= 16'h13E5; // COM8, re-enable AGC/AEC

            default: data <= 16'hFFFF; // end of ROM
        endcase
    end
endmodule
