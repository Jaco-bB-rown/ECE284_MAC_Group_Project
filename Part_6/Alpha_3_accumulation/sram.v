// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sram (CLK, D, Q, CEN, WEN, A_rd, A_wr);

  input  CLK;
  input  WEN;
  input  REN;
  input  CEN;
  input  [bw-1:0] D;
  input  [$clog2(num)-1:0] A_rd;
  input  [$clog2(num)-1:0] A_wr;
  output [bw-1:0] Q;
  parameter num = 2048;
  parameter bw = 32;

  reg [bw-1:0] memory [num-1:0];
  reg [$clog2(num)-1:0] add_q;
  assign Q = memory[add_q];

  always @ (posedge CLK) begin

   if (!CEN && !REN) // read 
      add_q <= A;
   if (!CEN && !WEN && (REN || A_wr != A_rd)) // write
      memory[A] <= D; 

  end

endmodule