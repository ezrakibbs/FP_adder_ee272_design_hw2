// 12 bit floating point multiplier module
//  - 1 sign
//  - 5 exponent
//  - 6 mantissa
`timescale 1ns/10ps

module testbench;

  logic clk;
  logic reset;
  logic [11:0] A;
  logic [11:0] B;
  logic [11:0] C;
  logic [11:0] D;
  logic pushin;
  reg pushout;
  reg [11:0] Z;

  fpa test(.clk(clk),
           .reset(reset),
           .A(A),
           .B(B),
           .C(C),
           .D(D),
           .pushin(pushin),
           .pushout(pushout),
           .Z(Z));
  
  initial begin
    clk = 0;
    reset = 1;
    pushin = 0;
    #8
    reset = 0;
    pushin = 1;
    #1000
    $finish;
  end

  initial begin
    forever begin
      #5 clk = ~clk;
    end
  end

  initial begin
    #14
    A = 12'b0_10101_000010;
    B = 12'b0_10101_000010;
    C = 12'b1_10111_000110;
    D = 12'b0_10101_000010;
    #10
    A = 0;
    B = 0;
    C = 12'b1_10111_000110;
    D = 0;
    #10
    A = 12'b0_10101_011101;
    B = 12'b0_10101_011101;
    C = 12'b1_10111_000110;
    D = 12'b0_10101_011101;
    #10
    A = 12'b0_10101_011110;
    B = 12'b0_10101_011101;
    C = 12'b1_10111_000110;
    D = 12'b0_10101_011101;
    #10;
  end






endmodule