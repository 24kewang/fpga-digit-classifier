`timescale 1ns / 1ps

module ov7670_sccb_config #(
    parameter int CLK_FREQ = 25_000_000  // Hz
)(
    input  logic clk,
    input  logic reset,

    input  logic sccb_ready,    // SCCB byte engine ready
    input  logic [15:0] rom_data,

    output logic [7:0] rom_addr,
    output logic done,

    output logic [7:0] sccb_addr,
    output logic [7:0] sccb_data,
    output logic       sccb_start
);

    typedef enum logic [1:0] {
        FSM_IDLE,
        FSM_SEND,
        FSM_TIMER,
        FSM_DONE
    } state_t;

    state_t state, ret_state;
    logic [31:0] timer;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= FSM_IDLE;
            rom_addr    <= 0;
            done        <= 0;
            sccb_addr   <= 0;
            sccb_data   <= 0;
            sccb_start  <= 0;
            timer       <= 0;
        end else begin
            // default output
            sccb_start <= 0;

            case (state)

                FSM_IDLE: begin
                    
                    if (!done) begin
                        rom_addr <= 0;
                        state    <= FSM_SEND;
                    end
                end

                FSM_SEND: begin
                    unique case (rom_data)

                        16'hFFFF: begin
                            // End of config table
                            state <= FSM_DONE;
                        end

                        16'hFFF0: begin
                            // delay entry (10ms)
                            timer       <= CLK_FREQ / 100;
                            ret_state   <= FSM_SEND;
                            state       <= FSM_TIMER;
                            rom_addr    <= rom_addr + 1;
                        end

                        default: begin
                            if (sccb_ready) begin
                                sccb_addr  <= rom_data[15:8];
                                sccb_data  <= rom_data[7:0];
                                sccb_start <= 1;

                                // one cycle delay before writing next
                                timer       <= 1;
                                ret_state   <= FSM_SEND;
                                state       <= FSM_TIMER;
                                rom_addr    <= rom_addr + 1;
                            end
                        end
                    endcase
                end

                FSM_TIMER: begin
                    if (timer == 0)
                        state <= ret_state;
                    else
                        timer <= timer - 1;
                end

                FSM_DONE: begin
                    done  <= 1;
                    state <= FSM_IDLE;
                end

            endcase
        end
    end
endmodule
