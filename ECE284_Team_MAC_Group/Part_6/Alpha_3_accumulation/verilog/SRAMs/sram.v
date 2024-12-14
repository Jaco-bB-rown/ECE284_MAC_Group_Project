// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sram_db (CLK, D, Q, CEN, REN, WEN, A_rd, A_wr);

  input  CLK;
  input  WEN;
  input  REN;
  input  CEN;
  input  [bw-1:0] D;
  input  [$clog2(num)-1:0] A_rd;
  input  [$clog2(num)-1:0] A_wr;
  output [bw-1:0] Q;
  parameter num = 2048;
  parameter bw = 128;
  integer i;

  reg [bw-1:0] memory [num-1:0];
  reg [$clog2(num)-1:0] add_q;
  assign Q = memory[add_q];

   initial begin
      for (i = 0; i < num; i = i + 1) begin
         memory [i] = 0;
      if (i == 22) begin
         memory [i] = 1;
      end
      end
   end

  always @ (posedge CLK) begin

   if (!CEN && !REN) // read 
      add_q <= A_rd;
   if (!CEN && !WEN && (REN || A_wr != A_rd)) // write
      memory[A_wr] <= D; 

  end

endmodule

module sram (CLK, D, Q, CEN, WEN, A);

  input  CLK;
  input  WEN;
  input  CEN;
  input  [bw-1:0] D;
  input  [$clog2(num)-1:0] A;
  output [bw-1:0] Q;
  parameter num = 2048;
  parameter bw = 32;

  reg [bw-1:0] memory [num-1:0];
  reg [$clog2(num)-1:0] add_q;
  assign Q = memory[add_q];

  always @ (posedge CLK) begin

   if (!CEN && WEN) // read 
      add_q <= A;
   if (!CEN && !WEN) // write
      memory[A] <= D; 

  end

endmodule