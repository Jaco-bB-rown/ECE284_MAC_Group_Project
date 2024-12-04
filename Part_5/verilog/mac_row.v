// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_row (clk, out_s, in_w, in_n, valid, inst_w, reset, mode_select);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter inst_bw = 2;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  output [col-1:0] valid;
  input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  input  mode_select;

  wire  [(col+1)*bw-1:0] temp;
  wire  [(col+1)*inst_bw-1:0] inst_temp;

  assign temp[bw-1:0]   = in_w;
  assign inst_temp[inst_bw-1:0] = inst_w;

  genvar i;
  for (i=1; i < col+1 ; i=i+1) begin : col_num
      mac_tile #(.bw(bw), .psum_bw(psum_bw)) mac_tile_instance (
         .clk(clk),
         .reset(reset),
	       .in_w( temp[bw*i-1:bw*(i-1)]),
	       .out_e(temp[bw*(i+1)-1:bw*i]),
	       .inst_w(inst_temp[i*inst_bw-1:(i-1)*(inst_bw)]),
	       .inst_e(inst_temp[(i+1)*inst_bw-1:(i)*(inst_bw)]),
	       .in_n(in_n[i*psum_bw-1:(i-1)*(psum_bw)]),
	       .out_s(out_s[(i)*psum_bw-1:(i-1)*(psum_bw)])
         .mode_select(mode_select));
         //set valid as inst_e[1] for each tile
         assign valid[i-1] = inst_temp[((i+1)*inst_bw-1)];
  end

endmodule