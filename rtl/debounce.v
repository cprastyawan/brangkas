module debounce #(
    parameter COUNTER_MAX = 666_666 // Tahan ~20ms pada clock 33.33 MHz
)(
    input  wire clk,
    input  wire btn_in,
    output reg  btn_out
);

    // 2-stage synchronizer untuk mencegah metastabilitas
    reg btn_sync_0 = 0;
    reg btn_sync_1 = 0;

    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    // Counter untuk penstabil sinyal
    reg [19:0] count = 0;

    always @(posedge clk) begin
        if (btn_sync_1 != btn_out) begin
            count <= count + 1'b1;
            if (count >= COUNTER_MAX - 1) begin
                btn_out <= btn_sync_1;
                count   <= 0;
            end
        end else begin
            count <= 0;
        end
    end

endmodule