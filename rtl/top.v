`timescale 1ns/1ps

module top (
    input clk, rstn,
    input [3:0] sw,
    input [3:0] btn,
    output led6_r,
    output led6_g,
    output led6_b
);
    assign led6_r = sw[0] & btn[0];
    assign led6_g = sw[1] & btn[1];
    assign led6_b = sw[2] & btn[2] & btn[3] | sw[3];
endmodule