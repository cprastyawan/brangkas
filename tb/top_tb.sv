`timescale 1ns/1ps

module top_tb();
    reg clk = 0, rstn = 1;
    reg [3:0] sw = 4'b0;
    reg [3:0] btn = 4'b0;
    wire led6_r;
    wire led6_g;
    wire led6_b;
    
    initial begin
        for(int i = 0; i < 16; i++) begin
            @(posedge clk);
            btn = i;
            @(posedge clk);
            sw = ~i;
        end
        #16
        $finish();
    end

    always #1 clk = ~clk;

    top uut(.clk(clk), .rstn(rstn), .sw(sw), .btn(btn), 
    .led6_r(led6_r), .led6_g(led6_g), .led6_b(led6_b));
endmodule