// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid, mode, output_en);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  output [col-1:0] valid;
  input mode;
  input output_en;


  reg    [2*row-1:0] inst_w_temp;
  reg    [row-1:0] output_en_temp;
  wire   [psum_bw*col*(row+1)-1:0] temp;
  wire   [row*col-1:0] valid_temp;

  //wire   [row*bw-1:0] stationary_weights;  // Weights used in weight-stationary mode
  //wire   [psum_bw*col-1:0] stationary_psums; // PSUMs used in output-stationary mode
  //wire   [row*bw-1:0] mux_weights;
  //wire   [psum_bw*col-1:0] mux_psums;

  genvar i;
 
  assign out_s = temp[psum_bw*col*9-1:psum_bw*col*8];
  assign temp[psum_bw*col-1:0] = in_n;
  assign valid = valid_temp[row*col-1:row*col-8];

  //assign mux_weights = mode ? in_w : stationary_weights;
  //assign mux_psums = mode ? stationary_psums : in_n;
  
  generate for (i=1; i < row+1 ; i=i+1) begin : row_num
      mac_row #(.bw(bw), .psum_bw(psum_bw), .col(col)) mac_row_instance (
         .clk(clk),
         .reset(reset),
	       .in_w(in_w[bw*i-1:bw*(i-1)]),
	       .inst_w(inst_w_temp[2*i-1:2*(i-1)]),
	       .in_n(temp[psum_bw*col*i-1:psum_bw*col*(i-1)]),
         .valid(valid_temp[col*i-1:col*(i-1)]),
	       .out_s(temp[psum_bw*col*(i+1)-1:psum_bw*col*(i)]),
         .mode_select(mode),
         .output_en(output_en_temp[i-1]));
  end
  endgenerate
  integer j;
  always @ (posedge clk) begin
    //valid <= valid_temp[row*col-1:row*col-8];
    inst_w_temp[1:0]   <= inst_w; 
    inst_w_temp[3:2]   <= inst_w_temp[1:0]; 
    inst_w_temp[5:4]   <= inst_w_temp[3:2]; 
    inst_w_temp[7:6]   <= inst_w_temp[5:4]; 
    inst_w_temp[9:8]   <= inst_w_temp[7:6]; 
    inst_w_temp[11:10] <= inst_w_temp[9:8]; 
    inst_w_temp[13:12] <= inst_w_temp[11:10]; 
    inst_w_temp[15:14] <= inst_w_temp[13:12]; 

    if(mode)begin//start outputting from the bottom then go to the top
      output_en_temp[row-1] <= output_en;
      for(j=0;j<row-1;j=j+1)begin
          output_en_temp[j] <= output_en;
      end
    end
  end



endmodule
