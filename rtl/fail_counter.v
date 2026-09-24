module fail_counter (
    input  wire       clk,
    input  wire       rst,          // Reset counter ke 0 (misal dari BTN2 atau saat PIN_TRUE)
    input  wire       inc_count,    // Pulsa pemicu penambahan counter (saat verifikasi PIN_FALSE)
    output reg  [1:0] fail_count,   // Nilai counter saat ini (0 sampai 3)
    output wire       max_reached   // High (1) jika kegagalan sudah mencapai 3 kali
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fail_count <= 2'b00;    // Reset hitungan ke 0
        end else if (inc_count) begin
            if (fail_count < 2'd3) begin
                fail_count <= fail_count + 1'b1; // Tambah 1 jika belum mencapai 3
            end
        end
    end

    // Sinyal indikasi bahwa batas maksimum 3 kali gagal telah tercapai
    assign max_reached = (fail_count >= 2'd3);

endmodule