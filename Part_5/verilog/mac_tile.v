// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, mode_select, output_en);

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
input  mode_select;
input  output_en;


wire [psum_bw-1:0] mac_out;
reg [1:0]inst_q;
reg [bw-1:0]a_q;
reg [bw-1:0]b_q;
reg [psum_bw-1:0]c_q;
reg load_ready_q;

//reg output_select;
wire [psum_bw-1:0]b_q_signext;

assign b_q_signext = { {psum_bw-bw{b_q[bw-1]}}, b_q };
assign out_e = a_q;
assign inst_e = inst_q;
assign out_s = (mode_select && !output_en) ? b_q_signext : mac_out;

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q), 
        .b(b_q),
        .c(c_q),
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
                if (inst_w != 2'b00) begin
                        if (!mode_select) begin
                                // Weight-Stationary Mode: Send weight to MAC
                                a_q <= in_w;                // Activate input (west) to east output
                                c_q <= in_n;                // Feature map (activation) to MAC
                                //output_select <= 0;
                                if (inst_w[0] == 1'b1 && load_ready_q == 1'b1) begin
                                        b_q <= in_w;        // Load weight
                                        load_ready_q <= 1'b0;
                                end
                        end
                        else begin// Output-Stationary Mode: Send output to MAC
                                //this if not used for O.s.
                                /*if (inst_w[0] == 1'b1 && load_ready_q == 1'b1) begin//load signal now defines when we output
                                        a_q <= 0;           // Feature map (activation) input
                                        b_q <= 0;           // Load weight
                                        c_q <= mac_out;     // Output from MAC
                                        output_select <= 0;
                                        load_ready_q <= 1'b0;
                                end*/
                                if(output_en && load_ready_q)begin
                                        a_q <= 0;           // Feature map (activation) input
                                        b_q <= 0;           // Load weight
                                        c_q <= in_n;     // Output from MAC
                                        //output_select <= 0;
                                        load_ready_q <= 1'b0;
                                end
                                else if(output_en)begin
                                        c_q <= in_n;
                                        a_q <= 0;           // Feature map (activation) input
                                        b_q <= 0;           // Load weight
                                        //output_select <= 0;
                                end
                                else begin
                                        //output_select <= 1;
                                        c_q <= mac_out;     // Output from MAC
                                        a_q <= in_w;        // Feature map (activation) input
                                        b_q <= in_n;        // Load weight
                                end
                        end
                end

                if(load_ready_q == 1'b0) begin //then pass inst next clock
                        inst_q[0] <= inst_w[0];
                end
        end
end


endmodule
