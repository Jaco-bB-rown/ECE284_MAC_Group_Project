// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);

parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

wire [bw-1:0]a_q_t;
wire [psum_bw-1:0]c_q_t;
wire skip;
wire [psum_bw-1:0] mac_out;

reg [1:0]inst_q;
reg [bw-1:0]a_q;
reg [bw-1:0]b_q;
reg [psum_bw-1:0]c_q;
reg load_ready_q;

assign out_e = a_q;
assign inst_e = inst_q;
assign out_s = skip ? c_q:mac_out;
assign a_q_t = skip ? 0:a_q;
assign c_q_t = skip ? 0:c_q;
assign skip = (a_q == 0) || (b_q == 0);

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q_t), 
        .b(b_q),
        .c(c_q_t),
	.out(mac_out)
); 

always@(posedge clk) begin
        if(reset) begin //synchronous reset
                inst_q[1:0] <= 2'b0;
                load_ready_q <= 1'b1;
                a_q <= 0;
                b_q <= 0;
                c_q <= 0;
        end
        else begin
                inst_q[1] <= inst_w[1]; //always accept
                if(inst_w != 0) begin//always pass west to the east
                        a_q <= in_w;
                        c_q <= in_n;
                end
                if(inst_w[0] == 1'b1 && load_ready_q == 1'b1) begin //load weight
                        b_q <= in_w; 
                        load_ready_q <= 1'b0;
                end
                if(load_ready_q == 1'b0) begin //then pass inst next clock
                        inst_q[0] <= inst_w[0];
                end
        end
end


endmodule
