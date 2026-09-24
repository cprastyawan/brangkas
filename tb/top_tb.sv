`timescale 1ns/1ps

module top_tb();
    reg clk = 0, rstn = 1;
    reg [3:0] sw = 4'b0;
    reg [3:0] btn = 4'b0;
    wire led6_r;
    wire led6_g;
    wire led6_b;
    
    initial begin
        #1
        rstn = 0;
        #10
        rstn = 1;
        #1000
        $finish();
    end

    always #1 clk = ~clk;

    top uut(.clk(clk), .rstn(rstn), .sw(sw), .btn(btn), 
    .led6_r(led6_r), .led6_g(led6_g), .led6_b(led6_b));
endmodule