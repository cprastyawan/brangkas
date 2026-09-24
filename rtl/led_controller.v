module led_controller (
    input  wire [3:0] state,      // Sinyal state dari FSM
    input  wire       clk_blink,  // Sinyal clock lambat (~1-2 Hz) dari clock_divider
    output reg        led6_r,     // Output LED Merah (V16)
    output reg        led6_g,     // Output LED Hijau (F17)
    output reg        led6_b      // Output LED Biru  (M17)
);

    // Pengkodean State (Sesuai Proposal)
    localparam IDLE       = 4'b0000;
    localparam PIN_TRUE   = 4'b0001;
    localparam PIN_FALSE  = 4'b0010;
    localparam LOCKED     = 4'b0100;
    localparam PIN_CHANGE = 4'b1000;

    // Logika Pemilihan Warna LED {R, G, B}
    always @(*) begin
        case (state)
            IDLE: begin
                // LED Mati (0,0,0)
                {led6_r, led6_g, led6_b} = 3'b000;
            end
            
            PIN_TRUE: begin
                // LED Hijau (0,1,0)
                {led6_r, led6_g, led6_b} = 3'b010;
            end
            
            PIN_FALSE: begin
                // LED Biru (0,0,1)
                {led6_r, led6_g, led6_b} = 3'b001;
            end
            
            PIN_CHANGE: begin
                // LED Ungu / Red + Blue (1,0,1)
                {led6_r, led6_g, led6_b} = 3'b101;
            end
            
            LOCKED: begin
                // LED Merah Kelap-kelip (1,0,0 saat clk_blink HIGH)
                {led6_r, led6_g, led6_b} = clk_blink ? 3'b100 : 3'b000;
            end
            
            default: begin
                {led6_r, led6_g, led6_b} = 3'b000;
            end
        endcase
    end

endmodule