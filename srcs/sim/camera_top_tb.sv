// Use tb_digit_cnn for testing the neural network modules with a generated test image module

module tb_digit_cnn();
timeunit 10ns;  // This is the amount of time represented by #1 
timeprecision 1ns;
    // Clock and reset
    logic clk;
    logic rst;
    
    // Control signals
    logic start;
    logic valid;
    
    // Data signals
    logic [5:0] pixels [0:783];
    logic [3:0] digit;
    
    // Clock generation - 10MHz (100ns period)
    initial begin: CLOCK_INITIALIZATION
        clk = 1'b1;
    end 
    
    // Toggle the clock
    // #1 means wait for a delay of 1 timeunit, so simulation clock is 50 MHz technically 
    // half of what it is on the FPGA board 
    
    // Note: Since we do mostly behavioral simulations, timing is not accounted for in simulation, however
    // this is important because we need to know what the time scale is for how long to run
    // the simulation
    always begin : CLOCK_GENERATION
        #1 clk = ~clk;
    end
    
    // Instantiate test_image module
    test_image test_img (
        .pixels(pixels)
    );
    
    // Instantiate digit_cnn module
    digit_cnn dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .pixels(pixels),
        .digit(digit),
        .valid(valid)
    );
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst = 1;
        start = 0;
        
        // Hold reset for a few cycles
        repeat(5) @(posedge clk);
        rst = 0;
        
        // Wait a few cycles after reset
        repeat(3) @(posedge clk);
        
        // Assert start signal for a few cycles
        start = 1;
        repeat(3) @(posedge clk);
        start = 0;
        
        $display("Time=%0t: Start signal asserted, waiting for computation...", $time);
        
        // Wait for valid signal to go high (with timeout)
        fork
            begin
                // Wait for valid with timeout
                wait(valid == 1);
                $display("Time=%0t: Computation complete! Predicted digit = %0d", $time, digit);
            end
            begin
                // Timeout after 1,000,000 clock cycles
                repeat(100000000) @(posedge clk);
                $display("Time=%0t: WARNING - Timeout reached, valid signal not asserted", $time);
            end
        join_any
        
        // Wait a few more cycles to see the output
        repeat(10) @(posedge clk);
        
        // Finish simulation
        $display("Time=%0t: Simulation finished", $time);
        $finish;
    end
    
    // Monitor output
    always @(posedge clk) begin
        if (valid) begin
            $display("Time=%0t: Valid output detected - Digit = %0d", $time, digit);
        end
    end

endmodule


// Uncomment the following camera_top_tb module to test the SCCB and camera modules

//`timescale 1ns/1ps

//module camera_top_tb;

//    // DUT inputs
//    logic Clk;
//    logic reset_rtl_0;

//    logic cam_pclk;
//    logic cam_vsync;
//    logic cam_href;
//    logic [7:0] cam_d;

//    // DUT outputs
//    wire cam_xclk;
//    wire cam_sioc;
//    wire cam_siod;
//    wire hdmi_tmds_clk_n;
//    wire hdmi_tmds_clk_p;
//    wire [2:0] hdmi_tmds_data_n;
//    wire [2:0] hdmi_tmds_data_p;

//    // Instantiate DUT
//    camera_top dut (
//        .Clk(Clk),
//        .reset_rtl_0(reset_rtl_0),

//        .cam_xclk(cam_xclk),
//        .cam_sioc(cam_sioc),
//        .cam_siod(cam_siod),
//        .cam_pclk(cam_pclk),
//        .cam_vsync(cam_vsync),
//        .cam_href(cam_href),
//        .cam_d(cam_d),

//        .hdmi_tmds_clk_n(hdmi_tmds_clk_n),
//        .hdmi_tmds_clk_p(hdmi_tmds_clk_p),
//        .hdmi_tmds_data_n(hdmi_tmds_data_n),
//        .hdmi_tmds_data_p(hdmi_tmds_data_p)
//    );

//    // =============================================================
//    // CLOCK GENERATION
//    // =============================================================

//    always #5  Clk = ~Clk;      // 100 MHz
//    always #20 cam_pclk = ~cam_pclk; // ~=25 MHz

//    // =============================================================
//    // TESTBENCH SIGNAL GENERATION
//    // =============================================================
    
//    initial begin
//        Clk = 0;
//        cam_pclk = 0;
//        reset_rtl_0 = 1;
//        cam_vsync = 0;
//        cam_href  = 0;
//        cam_d     = 0;

//        #100;
//        reset_rtl_0 = 0;

//        // Allow SCCB config time
//        #200000;
//        $display("[TB] SCCB config should now be complete");

//        // Assert SCCB has finished
//        assert (dut.sccb_cfg.done == 1)
//            else $fatal("[ASSERT] SCCB did not complete configuration!");

//        $display("[TB] Starting simulated frame input");

//        cam_vsync = 1;
//        #200;
//        cam_vsync = 0;

//        cam_href = 1;
//        send_pixel(8'h12, 8'h34); // pixel #0
//        send_pixel(8'hAB, 8'hCD); // pixel #1
//        cam_href = 0;
//        #200;

//        cam_href = 1;
//        send_pixel(8'h11, 8'h22);
//        send_pixel(8'h33, 8'h44);
//        cam_href = 0;

//        cam_vsync = 1;
//        #100;
//        cam_vsync = 0;

//        #2000;
//        $display("[TB] Simulation finished successfully");
//        $finish;
//    end

//    // =============================================================
//    // PIXEL SEND TASK
//    // =============================================================
//    task send_pixel(input [7:0] hi, input [7:0] lo);
//    begin
//        @(posedge cam_pclk);
//        cam_d = hi;

//        @(posedge cam_pclk);
//        cam_d = lo;
//    end
//    endtask

//    // =============================================================
//    // ASSERTIONS
//    // =============================================================

//    // 1. `bram_we` must NEVER occur on the high byte
//property pixel_write_only_on_low_byte;
//    @(posedge cam_pclk) disable iff (reset_rtl_0)
//        (dut.capture_inst.byte_phase == 1) |-> (dut.capture_inst.bram_we == 1);
//endproperty
//assert property(pixel_write_only_on_low_byte)
//    else $fatal("[ASSERT] BRAM write occurred on wrong byte!");


//    // 2. BRAM write enable must pulse only for one cycle
//   property bram_we_one_cycle;
//    @(posedge cam_pclk) disable iff (reset_rtl_0)
//        dut.capture_inst.bram_we |-> ##1 !dut.capture_inst.bram_we;
//endproperty
//assert property(bram_we_one_cycle)
//    else $fatal("[ASSERT] BRAM write lasted longer than 1 cycle!");


//    // 3. Pixel address increments correctly
// property address_increments;
//    @(posedge cam_pclk) disable iff(reset_rtl_0)
//        dut.capture_inst.bram_we |=> (dut.capture_inst.addr == $past(dut.capture_inst.addr) + 1);
//endproperty
//assert property(address_increments)
//    else $fatal("[ASSERT] Address failed to auto-increment!");


//    // 4. Optional: check RGB333 correctness for sample pixel
//    // Expected conversion: R=hi[7:5], G=hi[4:2], B=lo[4:2]
//    logic [8:0] expected_rgb;
//    always_comb expected_rgb = {cam_d[7:5], cam_d[4:2], cam_d[4:2]}; // only valid on writes

//    property rgb_conversion_correct;
//        @(posedge cam_pclk) disable iff(reset_rtl_0)
//            dut.capture_inst.bram_we |-> dut.capture_inst.bram_din == expected_rgb;
//    endproperty
//    // Uncomment if you want strict checking:
//    // assert property(rgb_conversion_correct) else $fatal("[ASSERT] RGB333 conversion incorrect!");

//endmodule
