`timescale 1ns/1ps

module downsample_2x2_avg #(
    parameter BOX_WIDTH  = 56,
    parameter BOX_HEIGHT = 56
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        vde,
    input  logic [9:0]  drawX, drawY,
    input  logic [5:0]  pixel_in,
    input  logic [9:0]  BOX_X, BOX_Y,

    output logic [5:0] cnn_out [0:783],
    output logic        frame_done
);

    // Inside the box?
    logic inside_box;
    logic [9:0] col, row;
    
    always_comb begin
        inside_box = (drawX >= BOX_X && drawX < BOX_X + BOX_WIDTH &&
                      drawY >= BOX_Y && drawY < BOX_Y + BOX_HEIGHT);

        col = drawX - BOX_X;
        row = drawY - BOX_Y;
    end

    // Detect last pixel of a 4×4 block
    logic is_last_of_block;
    always_comb begin
        is_last_of_block =
            inside_box &&
            (col[0] == 1'b1) &&
            (row[0] == 1'b1);
    end
    
    logic is_first_line;
    always_comb begin
        is_first_line = inside_box && (row[0] == 1'b0);
    end
    
    
    logic [5:0] line_buffer [0:55];
    // Accumulator
    logic [5:0] sum_acc;

    // Output index
    logic [9:0] curr_index;
    assign curr_index = ((row >> 1) * 28) + (col >> 1);

    logic [5:0] current_color;
    assign current_color = ({2'b0, line_buffer[col - 1]} + {2'b0, line_buffer[col]} + {2'b0, pixel_in} + {2'b0, sum_acc} ) >> 2;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            sum_acc    <= 0;
            frame_done <= 0;
        end else begin
            frame_done <= 0;

            if (vde && inside_box) begin
                if (is_first_line) begin
                    line_buffer[col] <= pixel_in;
                end
                else if (is_last_of_block) begin
                  
                    // Divide by 16
                    if (current_color < 24) begin
                        cnn_out[curr_index] <= 6'd63 - current_color;
                    end
                    else begin
                        cnn_out[curr_index] <= 6'b0;
                    end
//                    cnn_out[curr_index] <= ({2'b0, line_buffer[col - 1]} + {2'b0, line_buffer[col]} + {2'b0, pixel_in} + {2'b0, sum_acc} ) >> 2;
                    
                    if (curr_index == 783)
                        frame_done <= 1;

                    // Reset for next block
                    sum_acc <= 0;
                end else begin
                    sum_acc <= pixel_in;
                end
            end else begin
                sum_acc <= 0;
            end       
        end
    end
endmodule
