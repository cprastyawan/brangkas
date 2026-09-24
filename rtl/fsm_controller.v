`timescale 1ns/1ps

module fsm_controller (
    input clk, rst,
    input [3:0] btn,
    input pin_match,
    input max_reached,
    input [1:0] fail_count,
    output reg [3:0] state,
    output reg change_enable,
    output reg inc_fail,
    output reg rst_fail
);

    localparam IDLE       = 4'b0000;
    localparam PIN_TRUE   = 4'b0001;
    localparam PIN_FALSE  = 4'b0010;
    localparam LOCKED     = 4'b0100;
    localparam PIN_CHANGE = 4'b1000;

    reg [3:0] next_state;

    reg [3:0] btn_prev;
    wire [3:0] btn_pulse = btn & ~btn_prev;

    always @(posedge clk) begin
        if (rst) begin
            btn_prev <= 4'b0000;
        end else begin
            btn_prev <= btn;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        // Defaults every cycle: avoids inferred latches and guarantees every
        // output is driven on every path through the case below.
        next_state    = state;
        change_enable = 1'b0;
        inc_fail      = 1'b0;
        rst_fail      = 1'b0;

        case (state)
            IDLE: begin
                if (btn_pulse == 4'b0001) begin
                    if (pin_match) begin
                        next_state = PIN_TRUE;
                        rst_fail   = 1'b1;
                    end else begin
                        next_state = PIN_FALSE;
                        inc_fail = 1'b1;
                    end
                end
            end
            PIN_TRUE: begin
                if (btn_pulse == 4'b0010) begin
                    change_enable = 1'b1;
                    next_state    = PIN_CHANGE;
                end else if (btn_pulse == 4'b1000) begin
                    next_state = IDLE;
                end
            end
            PIN_FALSE: begin
                if (max_reached == 1) begin
                    next_state = LOCKED;
                end else begin
                    if (btn_pulse == 4'b0001) begin
                        if (pin_match) begin
                            next_state = PIN_TRUE;
                            rst_fail   = 1'b1;
                        end else begin
                            next_state = PIN_FALSE;
                            inc_fail = 1'b1;
                        end
                    end
                end
            end
            LOCKED: begin
                next_state = LOCKED; // only leaves via external reset (rstn)
            end
            PIN_CHANGE: begin
                if (btn_pulse == 4'b1000) begin
                    next_state = IDLE;
                end else next_state = PIN_CHANGE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
