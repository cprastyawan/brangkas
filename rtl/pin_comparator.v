module pin_comparator (
    input  wire       clk,
    input  wire       rst,            // Sinyal Reset
    input  wire [3:0] pin_in,         // Input PIN dari switch sw[3:0]
    input  wire       change_enable,  // Sinyal untuk simpan PIN baru (aktif saat state PIN_CHANGE)
    output wire       pin_match,      // High (1) jika PIN cocok, Low (0) jika salah
    output reg  [3:0] stored_pin      // Output opsional untuk monitoring PIN tersimpan
);

    // Nilai awal PIN default (misalnya 4'b0000)
    localparam DEFAULT_PIN = 4'b0000;

    // Logika Penyimpanan PIN
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stored_pin <= DEFAULT_PIN;  // Reset PIN ke nilai default
        end else if (change_enable) begin
            stored_pin <= pin_in;       // Simpan PIN baru dari switch
        end
    end

    // Logika Komparator (Kombinasional)
    // Menghasilkan sinyal 1 jika PIN input dari switch sama dengan PIN tersimpan
    assign pin_match = (pin_in == stored_pin);

endmodule