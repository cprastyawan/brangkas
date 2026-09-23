`timescale 1ns/1ps

module top (
    input clk, rstn,
    input [3:0] sw,
    input [3:0] btn,
    output led6_r,
    output led6_g,
    output led6_b
);

 //   debouncer u_debouncer();
 //   clk_divider u_clkdiv();

    assign led6_r = sw[0];
    assign led6_g = sw[1];
    assign led6_b = sw[2];
endmodule