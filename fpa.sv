// VERSION: 1.1

/* INSTRUCTIONS
Design a 4 input floating point adder.  

This will be synthesized to 1ns cycle time. 

Each input is a 12 bit floating point number with excess 15 exponent the same as the multiplier.

The test benches and run script are in ~morris/272/f25/hw2

You are limited to 8 cycles for the add.  It will probably not work using three 2 input adders.

The script will fail if the synthesis results do not meet the 1ns cycle time.
*/

/* STAGES

1) find largest exponent
2) align mantissas and determine zeros
3) 2's complement of all numbers
4) add all numbers
5) dummy stage
6) 2's complement of result
7) adjust exponent

*/

// 12 bit floating point multiplier module
//  - 1 sign
//  - 5 exponent
//  - 6 mantissa
`timescale 1ns/10ps

module fpa(input  reg clk,
           input  reg reset,
           input  reg [11:0] A,
           input  reg [11:0] B,
           input  reg [11:0] C,
           input  reg [11:0] D,
           input  reg pushin,
           output reg pushout,
           output reg [11:0] Z
);

  typedef struct packed{
    logic signbit;
    logic [4:0] exponent;
    logic [5:0] mantissa;
  } fp_12b;

  fp_12b a;
  fp_12b b;
  fp_12b c;
  fp_12b d;

  assign a = A;
  assign b = B;
  assign c = C;
  assign d = D;

  // stage 1: find largest exponent
  logic [4:0] largest_ab;
  logic [4:0] largest_cd;
  logic [4:0] largest_exponent;
  assign largest_ab = (a.exponent > b.exponent) ? a.exponent : b.exponent;
  assign largest_cd = (c.exponent > d.exponent) ? c.exponent : d.exponent;
  assign largest_exponent = (largest_ab > largest_cd) ? largest_ab : largest_cd;

  reg [4:0] s2_largest_exponent;
  fp_12b s2_a;
  fp_12b s2_b;
  fp_12b s2_c;
  fp_12b s2_d;
  reg s2_pushout;
  always@(posedge clk) begin
    if(reset | !pushin) begin
      s2_largest_exponent <= 0;
      s2_a <= 0;
      s2_b <= 0;
      s2_c <= 0;
      s2_d <= 0;
      s2_pushout <= 0;
    end

    else begin
      s2_largest_exponent <= largest_exponent;
      s2_a <= a;
      s2_b <= b;
      s2_c <= c;
      s2_d <= d;
      s2_pushout <= 1;
    end
  end

  // stage 2: align mantissas and determine zeros
  logic [13:0] shift_a;
  logic [13:0] shift_b;
  logic [13:0] shift_c;
  logic [13:0] shift_d;
  logic [3:0] zero_flag;

  assign shift_a = {4'b0001, s2_a.mantissa, 4'b0000} >> (s2_largest_exponent - s2_a.exponent);
  assign shift_b = {4'b0001, s2_b.mantissa, 4'b0000} >> (s2_largest_exponent - s2_b.exponent);
  assign shift_c = {4'b0001, s2_c.mantissa, 4'b0000} >> (s2_largest_exponent - s2_c.exponent);
  assign shift_d = {4'b0001, s2_d.mantissa, 4'b0000} >> (s2_largest_exponent - s2_d.exponent);

  always@(*) begin
    zero_flag = 0;
    if((s2_a.exponent == 0) & (s2_a.mantissa == 0)) begin
      zero_flag[0] = 1;
    end

    if((s2_b.exponent == 0) & (s2_b.mantissa == 0)) begin
      zero_flag[1] = 1;
    end

    if((s2_c.exponent == 0) & (s2_c.mantissa == 0)) begin
      zero_flag[2] = 1;
    end

    if((s2_d.exponent == 0) & (s2_d.mantissa == 0)) begin
      zero_flag[3] = 1;
    end

  end

  reg [14:0] s3_a_normal_mantissa_w_guard;
  reg [14:0] s3_b_normal_mantissa_w_guard;
  reg [14:0] s3_c_normal_mantissa_w_guard;
  reg [14:0] s3_d_normal_mantissa_w_guard;
  reg [4:0] s3_largest_exponent;
  reg s3_pushout;
  always@(posedge clk) begin
    if(reset | !s2_pushout) begin
      s3_a_normal_mantissa_w_guard <= 0;
      s3_b_normal_mantissa_w_guard <= 0;
      s3_c_normal_mantissa_w_guard <= 0;
      s3_d_normal_mantissa_w_guard <= 0;
      s3_largest_exponent <= 0;
      s3_pushout <= 0;
    end

    else begin
      s3_a_normal_mantissa_w_guard <= zero_flag[0] ? 0 : {s2_a.signbit, shift_a};
      s3_b_normal_mantissa_w_guard <= zero_flag[1] ? 0 : {s2_b.signbit, shift_b};
      s3_c_normal_mantissa_w_guard <= zero_flag[2] ? 0 : {s2_c.signbit, shift_c};
      s3_d_normal_mantissa_w_guard <= zero_flag[3] ? 0 : {s2_d.signbit, shift_d};
      s3_largest_exponent <= s2_largest_exponent;
      s3_pushout <= s2_pushout;
    end
  end

  // stage 3: 2's complement
  logic [13:0] a_2s_comp_mantissa;
  logic [13:0] b_2s_comp_mantissa;
  logic [13:0] c_2s_comp_mantissa;
  logic [13:0] d_2s_comp_mantissa;

  // flip bits then add 1 for 2's complement if sign is negative 
  assign a_2s_comp_mantissa = s3_a_normal_mantissa_w_guard[14] ? (~(s3_a_normal_mantissa_w_guard[13:0])) + 1 : s3_a_normal_mantissa_w_guard[13:0];
  assign b_2s_comp_mantissa = s3_b_normal_mantissa_w_guard[14] ? (~(s3_b_normal_mantissa_w_guard[13:0])) + 1 : s3_b_normal_mantissa_w_guard[13:0];
  assign c_2s_comp_mantissa = s3_c_normal_mantissa_w_guard[14] ? (~(s3_c_normal_mantissa_w_guard[13:0])) + 1 : s3_c_normal_mantissa_w_guard[13:0];
  assign d_2s_comp_mantissa = s3_d_normal_mantissa_w_guard[14] ? (~(s3_d_normal_mantissa_w_guard[13:0])) + 1 : s3_d_normal_mantissa_w_guard[13:0];


  reg [13:0] s4_a_2s_comp_mantissa;
  reg [13:0] s4_b_2s_comp_mantissa;
  reg [13:0] s4_c_2s_comp_mantissa;
  reg [13:0] s4_d_2s_comp_mantissa;
  reg [4:0] s4_largest_exponent;
  reg s4_pushout;
  always@(posedge clk) begin
    if(reset | !s3_pushout) begin
      s4_a_2s_comp_mantissa <= 0;
      s4_b_2s_comp_mantissa <= 0;
      s4_c_2s_comp_mantissa <= 0;
      s4_d_2s_comp_mantissa <= 0;
      s4_largest_exponent <= 0;
      s4_pushout <= 0;
    end

    else begin
      s4_a_2s_comp_mantissa <= a_2s_comp_mantissa;
      s4_b_2s_comp_mantissa <= b_2s_comp_mantissa;
      s4_c_2s_comp_mantissa <= c_2s_comp_mantissa;
      s4_d_2s_comp_mantissa <= d_2s_comp_mantissa;
      s4_largest_exponent <= s3_largest_exponent;
      s4_pushout <= s3_pushout;
    end
end

// stage 4: addition
reg [13:0] s5_2s_comp_sum;
reg [4:0] s5_largest_exponent;
reg s5_pushout;

always@(posedge clk) begin
  if(reset | !s4_pushout) begin
    s5_2s_comp_sum <= 0;
    s5_largest_exponent <= 0;
    s5_pushout <= 0;
  end

  else begin
    s5_2s_comp_sum <= s4_a_2s_comp_mantissa + s4_b_2s_comp_mantissa + s4_c_2s_comp_mantissa + s4_d_2s_comp_mantissa;
    s5_largest_exponent <= s4_largest_exponent;
    s5_pushout <= s4_pushout;
  end
end

// stage 5: dummy stage
reg [13:0] s6_2s_comp_sum;
reg [4:0] s6_largest_exponent;
reg s6_pushout;

always@(posedge clk) begin
  if(reset | !s5_pushout) begin
    s6_2s_comp_sum <= 0;
    s6_largest_exponent <= 0;
    s6_pushout <= 0;
  end

  else begin
    s6_2s_comp_sum <= s5_2s_comp_sum;
    s6_largest_exponent <= s5_largest_exponent;
    s6_pushout <= s5_pushout;
  end
end

// stage 6: 2's complement of result
logic [12:0] reverse_2s_comp_sum;
assign reverse_2s_comp_sum = s6_2s_comp_sum[13] ? (~(s6_2s_comp_sum[12:0])) + 1 : s6_2s_comp_sum[12:0];

reg [12:0] s7_reverse_2s_comp_sum;
reg s7_sign_bit;
reg [4:0] s7_largest_exponent;
reg s7_pushout;
always@(posedge clk) begin
  if(reset | !s6_pushout) begin
    s7_reverse_2s_comp_sum <= 0;
    s7_sign_bit <= 0;
    s7_largest_exponent <= 0;
    s7_pushout <= 0;
  end

  else begin
    s7_reverse_2s_comp_sum <= reverse_2s_comp_sum;
    s7_sign_bit <= s6_2s_comp_sum[13];
    s7_largest_exponent <= s6_largest_exponent;
    s7_pushout <= s6_pushout;
  end
end

// stage 7: adjust exponent and produce final result
logic [3:0] index_of_first_one;
logic found;
logic [5:0] new_exponent;
logic [5:0] new_mantissa;
logic new_sign_bit;
logic [18:0] extended_sum;
assign extended_sum = {s7_reverse_2s_comp_sum, 6'b000000};
always@(*) begin
  index_of_first_one = 10;  // default index is 10
  found = 0;
  for(int i = 12; i >= 0; i--) begin
    if((s7_reverse_2s_comp_sum[i] == 1) & (found == 0)) begin
      index_of_first_one = i;
      found = 1;
    end
  end

  // calculate new exponent
  if(index_of_first_one >= 10) begin
    new_exponent = s7_largest_exponent + (index_of_first_one - 10);
  end
  else begin
    new_exponent = s7_largest_exponent - (10 - index_of_first_one);
  end

  // assign 6 bits of mantissa and sign bit
  new_mantissa = extended_sum[index_of_first_one - 1 + 6 -: 6];
  new_sign_bit = s7_sign_bit;

  if((new_exponent < 5'b00010) | (s7_reverse_2s_comp_sum == 0)) begin
    new_sign_bit = 0;
    new_exponent = 0;
    new_mantissa = 0;
  end

  else if({new_exponent, new_mantissa} > 11'b11110_110000) begin
    new_exponent = 6'b011110;
    new_mantissa = 6'b110000;
  end
end

always@(posedge clk) begin
  if(reset | !s7_pushout) begin
    Z <= 0;
    pushout <= 0;
  end

  else begin
    Z[11] <= new_sign_bit;
    Z[10:6] <= new_exponent[4:0];
    Z[5:0] <= new_mantissa;
    pushout <= s7_pushout;
  end
end

fp_12b z;
assign z = Z;




endmodule : fpa