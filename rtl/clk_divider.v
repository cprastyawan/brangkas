module clk_divider #(
    parameter INPUT_FREQUENCY   = 32'd125000000,
    parameter DESIRED_FREQUENCY = 32'd2   // out_clock toggles at 2x this - see note below
) (
    input clk, rstn,
    output reg out_clock
);
    reg [31:0] counter;

    // NOTE: out_clock toggles every (INPUT_FREQUENCY/DESIRED_FREQUENCY) input
    // clocks, so its own square-wave frequency is DESIRED_FREQUENCY/2, not
    // DESIRED_FREQUENCY. With the defaults above (125,000,000 / 2 = 2), that's
    // a toggle every 0.5s -> a clean, clearly visible 1 Hz blink on an LED.
    always @(posedge clk) begin
        if (!rstn) begin
            counter   <= 32'd0;
            out_clock <= 1'b0;
        end else begin
            if (counter < (INPUT_FREQUENCY / DESIRED_FREQUENCY) - 1) begin
                counter <= counter + 1'b1;
            end else begin
                out_clock <= ~out_clock;
                counter   <= 32'd0;
            end
        end
    end
endmodule
