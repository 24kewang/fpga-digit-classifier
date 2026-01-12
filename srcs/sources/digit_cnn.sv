// Top-level CNN module with BRAM integration (Q16.16 fixed-point)
module digit_cnn (
    input logic clk,
    input logic rst,
    input logic start,
    input logic [5:0] pixels [0:783],  // 784 pixels, 6-bit grayscale
    output logic [3:0] digit,           // 0-9 prediction
    output logic valid
);

    // State machine
    typedef enum logic [4:0] {
        IDLE,
        NORM_INPUT,
        LAYER1_INIT,
        LAYER1_MAC_WAIT1,
        LAYER1_MAC_WAIT1_2,
        LAYER1_MAC_WAIT2,
        LAYER1_MAC_COMPUTE,
        LAYER1_ACCUM_FINAL,
        LAYER1_RELU,
        LAYER2_INIT,
        LAYER2_MAC_WAIT1,
        LAYER2_MAC_WAIT1_2,
        LAYER2_MAC_WAIT2,
        LAYER2_MAC_COMPUTE,
        LAYER2_ACCUM_FINAL,
        ARGMAX,
        DONE
    } state_t;
    
    state_t state, next_state;
    
    // Normalized inputs (Q16.16)
    logic signed [31:0] norm_pixels [0:783];
    
    // Layer 1 outputs
    logic signed [31:0] z1 [0:9];
    logic signed [31:0] a1 [0:9];
    
    // Layer 2 outputs
    logic signed [31:0] z2 [0:9];
    
    // Counters
    logic [9:0] pixel_counter;  // 0-783
    logic [3:0] neuron_counter; // 0-9
    logic [9:0] mac_counter;    // 0-783 for layer1, 0-9 for layer2
    
    // BRAM interface signals
    logic [12:0] w1_addr;
    logic signed [31:0] w1_data;
    logic [3:0] b1_addr;
    logic signed [31:0] b1_data;
    logic [6:0] w2_addr;
    logic signed [31:0] w2_data;
    logic [3:0] b2_addr;
    logic signed [31:0] b2_data;
    
    // Instantiate BRAM modules
    bram_w1 W1_BRAM (
        .clka(clk),
        .addra(w1_addr),
        .douta(w1_data),
        .ena(1'b1)
    );
    
    bram_b1 B1_BRAM (
        .clka(clk),
        .addra(b1_addr),
        .douta(b1_data),
        .ena(1'b1)
    );
    
    bram_w2 W2_BRAM (
        .clka(clk),
        .addra(w2_addr),
        .douta(w2_data),
        .ena(1'b1)
    );
    
    bram_b2 B2_BRAM (
        .clka(clk),
        .addra(b2_addr),
        .douta(b2_data),
        .ena(1'b1)
    );
    
    // Pipeline registers
    logic signed [31:0] weight_reg;
    logic signed [31:0] input_reg;
    logic signed [63:0] mult_result;
    
    // State machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Datapath
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_counter <= 0;
            neuron_counter <= 0;
            mac_counter <= 0;
            valid <= 0;
            digit <= 0;
            
            for (int i = 0; i < 784; i++) begin
                norm_pixels[i] <= 0;
            end
            
            for (int i = 0; i < 10; i++) begin
                z1[i] <= 0;
                a1[i] <= 0;
                z2[i] <= 0;
            end
            
            weight_reg <= 0;
            input_reg <= 0;
            mult_result <= 0;
            w1_addr <= 0;
            b1_addr <= 0;
            w2_addr <= 0;
            b2_addr <= 0;
            
        end else begin
            case (state)
                IDLE: begin
                    valid <= 0;
                    if (start) begin
                        pixel_counter <= 0;
                        neuron_counter <= 0;
                        mac_counter <= 0;
                    end
                end
                
                NORM_INPUT: begin
                    if (pixel_counter < 784) begin
//                        if (pixels[pixel_counter] > 24) begin
                            norm_pixels[pixel_counter] <= $signed({26'b0, pixels[pixel_counter]}) * 32'sd1040; // Scale 6-bit color to 8-bit color, then convert to Q16.16
//                        end else begin
//                            norm_pixels[pixel_counter] <= 32'b0;
//                        end
                        pixel_counter <= pixel_counter + 1;
                    end
                end
                
                LAYER1_INIT: begin
                    b1_addr <= neuron_counter;
                    w1_addr <= neuron_counter * 784 + mac_counter;
                end
                
                LAYER1_MAC_WAIT1: ;
                LAYER1_MAC_WAIT1_2: ;
                LAYER1_MAC_WAIT2: begin
                    if (mac_counter == 0) begin
                        z1[neuron_counter] <= b1_data;
                    end
                    weight_reg <= w1_data;
                    input_reg <= norm_pixels[mac_counter];
                end
                
                LAYER1_MAC_COMPUTE: begin
                    // Start multiplication
                    mult_result <= $signed(weight_reg) * $signed(input_reg);
                    
                    // Accumulate previous result (from last COMPUTE cycle)
                    if (mac_counter > 0) begin
                        z1[neuron_counter] <= z1[neuron_counter] + mult_result[47:16];
                    end
                    
                    // Increment counter
                    mac_counter <= mac_counter + 1;
                end
                
                LAYER1_ACCUM_FINAL: begin
                    // Accumulate the LAST MAC result
                    z1[neuron_counter] <= z1[neuron_counter] + mult_result[47:16];
                    mac_counter <= 0;
                    // Move to next neuron or RELU
                    if (neuron_counter < 9) begin
                        neuron_counter <= neuron_counter + 1;
                    end else begin
                        neuron_counter <= 0;
                    end
                end
                
                LAYER1_RELU: begin
                    for (int i = 0; i < 10; i++) begin
                        a1[i] <= (z1[i][31] == 1'b1) ? 32'h00000000 : z1[i];
                    end
                end
                
                LAYER2_INIT: begin
                    b2_addr <= neuron_counter;
                    w2_addr <= neuron_counter * 10 + mac_counter;
                end
                
                LAYER2_MAC_WAIT1: ;
                LAYER2_MAC_WAIT1_2: ;
                
                LAYER2_MAC_WAIT2: begin
                    if (mac_counter == 0) begin
                        z2[neuron_counter] <= b2_data;
                    end
                    weight_reg <= w2_data;
                    input_reg <= a1[mac_counter];
                end
                
                LAYER2_MAC_COMPUTE: begin
                    mult_result <= $signed(weight_reg) * $signed(input_reg);
                    
                    if (mac_counter > 0) begin
                        z2[neuron_counter] <= z2[neuron_counter] + mult_result[47:16];
                    end
                    
                    mac_counter <= mac_counter + 1;
                end
                
                LAYER2_ACCUM_FINAL: begin
                    // Accumulate the LAST MAC result
                    z2[neuron_counter] <= z2[neuron_counter] + mult_result[47:16];
                    mac_counter <= 0;
                    if (neuron_counter < 9) begin
                        neuron_counter <= neuron_counter + 1;
                    end else begin
                        neuron_counter <= 0;
                    end
                end
                
                ARGMAX: begin
                    automatic logic [3:0] max_idx = 0;
                    automatic logic signed [31:0] max_val = z2[0];
                    
                    for (int i = 0; i < 10; i++) begin
                        if ($signed(z2[i]) > $signed(max_val)) begin
                            max_val = z2[i];
                            max_idx = i[3:0];
                        end
                    end
                    digit <= max_idx;
                end
                
                DONE: begin
                    valid <= 1;
                end
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: 
                if (start) next_state = NORM_INPUT;
                
            NORM_INPUT: 
                if (pixel_counter >= 784) next_state = LAYER1_INIT;
                
            LAYER1_INIT:
                next_state = LAYER1_MAC_WAIT1;
                
            LAYER1_MAC_WAIT1:
                next_state = LAYER1_MAC_WAIT1_2;
            
            LAYER1_MAC_WAIT1_2:
                next_state = LAYER1_MAC_WAIT2;
                
            LAYER1_MAC_WAIT2:
                next_state = LAYER1_MAC_COMPUTE;
                
            LAYER1_MAC_COMPUTE: begin
                if (mac_counter >= 783) begin
                    // Last MAC - need to accumulate its result
                    next_state = LAYER1_ACCUM_FINAL;
                end else begin
                    next_state = LAYER1_INIT;
                end
            end
            
            LAYER1_ACCUM_FINAL: begin
                if (neuron_counter >= 9)
                    next_state = LAYER1_RELU;
                else
                    next_state = LAYER1_INIT;
            end
                
            LAYER1_RELU:
                next_state = LAYER2_INIT;
                
            LAYER2_INIT:
                next_state = LAYER2_MAC_WAIT1;
                
            LAYER2_MAC_WAIT1:
                next_state = LAYER2_MAC_WAIT1_2;
                
            LAYER2_MAC_WAIT1_2:
                next_state = LAYER2_MAC_WAIT2;
                
            LAYER2_MAC_WAIT2:
                next_state = LAYER2_MAC_COMPUTE;
                
            LAYER2_MAC_COMPUTE: begin
                if (mac_counter >= 9) begin
                    next_state = LAYER2_ACCUM_FINAL;
                end else begin
                    next_state = LAYER2_INIT;
                end
            end
            
            LAYER2_ACCUM_FINAL: begin
                if (neuron_counter >= 9)
                    next_state = ARGMAX;
                else
                    next_state = LAYER2_INIT;
            end
                
            ARGMAX:
                next_state = DONE;
                
            DONE:
                if (!start) next_state = IDLE;
                
            default:
                next_state = IDLE;
        endcase
    end

endmodule