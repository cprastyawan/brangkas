`timescale 1ns/1ps

module top (
    input        clk,     // Clock utama 125 MHz dari board Zybo (Pin K17)
    //input        rstn,    // Active-low Reset
    input  [3:0] sw,      // Switch Input Pin sw[3:0]
    input  [3:0] btn,     // Button Input Mode btn[3:0]
    output       led6_r,  // Red RGB LED (Pin V16)
    output       led6_g,  // Green RGB LED (Pin F17)
    output       led6_b   // Blue RGB LED (Pin M17)
);

    // =========================================================================
    // 1. Sinyal Internal & Logika Reset
    // =========================================================================
    wire       rstn = ~btn[2];
    wire       rst = ~rstn;     // Mengubah active-low reset (rstn) menjadi active-high (rst)
    wire [3:0] btn_db;          // Output sinyal tombol yang sudah di-debounce
    wire [3:0] state;           // State dari FSM
    wire       pin_match;       // Indikator PIN cocok dari pin_comparator
    wire       max_reached;     // Indikator gagal 3x dari fail_counter
    wire [3:0] stored_pin;      // PIN tersimpan
    wire       change_enable;   // Sinyal izin ganti PIN dari FSM
    wire       inc_fail;        // Sinyal penambah gagal PIN dari FSM
    wire       rst_fail;        // Sinyal reset counter gagal dari FSM
    wire [1:0] fail_count;      // Nilai counter gagal saat ini, ke FSM (biar lock tepat di percobaan ke-3)
    wire       clk_div;         // ~1 Hz - dipakai KHUSUS untuk blink LED, bukan clock sistem

    // clk_div sengaja hanya diberikan ke led_controller (clk_blink) di bawah.
    // Semua modul lain jalan di clk 125 MHz asli, supaya FSM/debounce/pin
    // comparator tetap responsif terhadap penekanan tombol manusia.
    clk_divider u_clkdiv (
        .clk(clk), 
        .rstn(rstn), 
        .out_clock(clk_div)
    );

    // =========================================================================
    // 3. Instansiasi Modul Debouncer (4 Tombol)
    // =========================================================================
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : btn_debouncers
            debounce #(
                .COUNTER_MAX(1_000_000) // ~8ms pada clock 125 MHz - lihat catatan
                                         // debounce.v: counter internalnya cuma
                                         // 20-bit (maks ~1.05M), jadi nilai di
                                         // atas itu akan overflow diam-diam.
            ) u_debounce (
                .clk    (clk),
                .btn_in (btn[i]),
                .btn_out(btn_db[i])
            );
        end
    endgenerate

    // =========================================================================
    // 4. Instansiasi Modul PIN Comparator
    // =========================================================================
    pin_comparator u_pin_comp (
        .clk          (clk),
        .rst          (rst),
        .pin_in       (sw),
        .change_enable(change_enable),
        .pin_match    (pin_match),
        .stored_pin   (stored_pin)
    );

    // =========================================================================
    // 5. Instansiasi Modul Fail Counter
    // =========================================================================
    fail_counter u_fail_counter (
        .clk        (clk),
        .rst        (rst | rst_fail),
        .inc_count  (inc_fail),
        .fail_count (fail_count),   // Sekarang dipakai FSM untuk cek lock tepat waktu
        .max_reached(max_reached)
    );

    // =========================================================================
    // 6. Instansiasi Modul LED Controller
    // =========================================================================
    led_controller u_led_ctrl (
        .state    (state),
        .clk_blink(clk_div),
        .led6_r   (led6_r),
        .led6_g   (led6_g),
        .led6_b   (led6_b)
    );

    // =========================================================================
    // 7. Instansiasi Modul FSM (State Controller dari Temanmu)
    // =========================================================================
    // Catatan: Sesuaikan nama port di bawah ini jika modul buatan temanmu
    // memiliki penamaan variabel yang sedikit berbeda.
    fsm_controller u_fsm (
        .clk          (clk),
        .rst          (rst),
        .btn          (btn_db),        // Tombol yang sudah bebas bouncing
        .pin_match    (pin_match),     // Input dari pin_comparator
        .max_reached  (max_reached),   // Input dari fail_counter
        .fail_count   (fail_count),    // Input dari fail_counter (nilai sebelum increment cycle ini)
        .state        (state),         // Output state ke led_controller
        .change_enable(change_enable), // Output izin ganti PIN ke pin_comparator
        .inc_fail     (inc_fail),      // Output pulsa gagal ke fail_counter
        .rst_fail     (rst_fail)       // Output reset gagal ke fail_counter
    );

endmodule
