`timescale 1ns / 1ps

module SCCB_interface #(
    parameter int CLK_FREQ  = 25_000_000,
    parameter int SCCB_FREQ = 100_000
)(
    input  logic clk,
    input  logic reset,
    input  logic start,
    input  logic [7:0] address,
    input  logic [7:0] data,
    output logic ready,
    output logic SIOC_oe,
    output logic SIOD_oe
);

    localparam logic [7:0] CAMERA_ADDR = 8'h42;

    typedef enum logic [3:0] {
        FSM_IDLE,
        FSM_START_SIGNAL,
        FSM_LOAD_BYTE,
        FSM_TX_BYTE_1,
        FSM_TX_BYTE_2,
        FSM_TX_BYTE_3,
        FSM_TX_BYTE_4,
        FSM_END_SIGNAL_1,
        FSM_END_SIGNAL_2,
        FSM_END_SIGNAL_3,
        FSM_END_SIGNAL_4,
        FSM_DONE,
        FSM_TIMER
    } state_t;

    state_t state = FSM_IDLE;
    state_t return_state;

    logic [31:0] timer = 0;
    logic [7:0] latched_address;
    logic [7:0] latched_data;
    logic [1:0] byte_counter = 0;
    logic [7:0] tx_byte = 0;
    logic [3:0] bit_index = 0;


    always_ff @(posedge clk or posedge reset) begin
        
        if (reset) begin
        state         <= FSM_IDLE;
        ready         <= 1;
        SIOC_oe       <= 0;
        SIOD_oe       <= 0;
        timer         <= 0;
        byte_counter  <= 0;
        bit_index     <= 0;
        latched_address <= 0;
        latched_data    <= 0;
        tx_byte         <= 0;
        end else begin
        case (state)

            FSM_IDLE: begin
                bit_index    <= 0;
                byte_counter <= 0;

                if (start) begin
                    state           <= FSM_START_SIGNAL;
                    latched_address <= address;
                    latched_data    <= data;
                    ready           <= 0;
                end else begin
                    ready <= 1;
                end
            end

            FSM_START_SIGNAL: begin
                state        <= FSM_TIMER;
                return_state <= FSM_LOAD_BYTE;
                timer        <= CLK_FREQ / (4 * SCCB_FREQ);
                SIOC_oe      <= 0;
                SIOD_oe      <= 1;
            end

            FSM_LOAD_BYTE: begin
                state        <= (byte_counter == 3) ? FSM_END_SIGNAL_1 : FSM_TX_BYTE_1;
                byte_counter <= byte_counter + 1;
                bit_index    <= 0;

                case (byte_counter)
                    0: tx_byte <= CAMERA_ADDR;
                    1: tx_byte <= latched_address;
                    2: tx_byte <= latched_data;
                    default: tx_byte <= latched_data;
                endcase
            end

            FSM_TX_BYTE_1: begin
                state        <= FSM_TIMER;
                return_state <= FSM_TX_BYTE_2;
                timer        <= CLK_FREQ / (4 * SCCB_FREQ);
                SIOC_oe      <= 1;
            end

            FSM_TX_BYTE_2: begin
                state        <= FSM_TIMER;
                return_state <= FSM_TX_BYTE_3;
                timer        <= CLK_FREQ / (4 * SCCB_FREQ);
                SIOD_oe      <= (bit_index == 8) ? 0 : ~tx_byte[7];
            end

            FSM_TX_BYTE_3: begin
                state        <= FSM_TIMER;
                return_state <= FSM_TX_BYTE_4;
                timer        <= CLK_FREQ / (2 * SCCB_FREQ);
                SIOC_oe      <= 0;
            end

            FSM_TX_BYTE_4: begin
                state     <= (bit_index == 8) ? FSM_LOAD_BYTE : FSM_TX_BYTE_1;
                tx_byte   <= tx_byte << 1;
                bit_index <= bit_index + 1;
            end

            FSM_END_SIGNAL_1: begin
                state        <= FSM_TIMER;
                return_state <= FSM_END_SIGNAL_2;
                timer        <= CLK_FREQ / (4 * SCCB_FREQ);
                SIOC_oe      <= 1;
            end

            FSM_END_SIGNAL_2: begin
                state        <= FSM_TIMER;
                return_state <= FSM_END_SIGNAL_3;
                timer        <= CLK_FREQ / (4 * SCCB_FREQ);
                SIOD_oe      <= 1;
            end

            FSM_END_SIGNAL_3: begin
                state        <= FSM_TIMER;
                return_state <= FSM_END_SIGNAL_4;
                timer        <= CLK_FREQ / (4 * SCCB_FREQ);
                SIOC_oe      <= 0;
            end

            FSM_END_SIGNAL_4: begin
                state        <= FSM_TIMER;
                return_state <= FSM_DONE;
                timer        <= CLK_FREQ / (4 * SCCB_FREQ);
                SIOD_oe      <= 0;
            end

            FSM_DONE: begin
                state        <= FSM_TIMER;
                return_state <= FSM_IDLE;
                timer        <= (2 * CLK_FREQ) / SCCB_FREQ;
                byte_counter <= 0;
            end

            FSM_TIMER: begin
                if (timer == 0) state <= return_state;
                else            timer <= timer - 1;
            end
        endcase
        end
    end

endmodule
