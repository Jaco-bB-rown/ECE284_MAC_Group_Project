module corelet #(
    parameter bw = 4,
    parameter row = 8,
    parameter col = 8,
    parameter psum_bw = 16
)(
    input wire clk,
    input wire reset,
    input wire [bw*row-1:0] activation_in,
    input wire [bw*row-1:0] weight_in,
    input wire [psum_bw*col-1:0] sfp_in,
    output wire [psum_bw*col-1:0] corelet_out,
    output wire o_ready,
    output wire o_valid,
    input wire [7:0] inst
);

    // Internal signals
    wire [psum_bw*col-1:0] mac_array_out;
    wire [col-1:0] mac_array_valid;
    wire l0_fifo_full, l0_fifo_ready;
    wire [bw*row-1:0] l0_fifo_out;
    wire [psum_bw*col-1:0] mac_array_in_n;//not used in this part
    wire ofifo_full, ofifo_ready, ofifo_valid;
    wire [psum_bw*col-1:0] ofifo_out, sfp_out;

    // Extract control signals from inst
    wire ofifo_rd ;
    wire ififo_wr ;//ififo not present in this part
    wire ififo_rd;
    wire l0_rd ;
    wire l0_wr ;

    assign ofifo_rd = inst[6];
    assign ififo_wr = inst[5];//ififo not present in this part
    assign ififo_rd = inst[4];
    assign l0_rd = inst[3];
    assign l0_wr = inst[2];

    assign o_ready = ofifo_ready;
    assign corelet_out = inst[7] ? sfp_out : ofifo_out;
    // L0 FIFO
    l0_fifo #(.bw(bw), .row(row)) l0_fifo_inst (
        .clk(clk),
        .in(activation_in),
        .out(l0_fifo_out),
        .rd(l0_rd),
        .wr(l0_wr),
        .o_full(l0_fifo_full),
        .reset(reset),
        .o_ready(l0_fifo_ready)
    );

    // OFIFO
    ofifo #(.bw(psum_bw), .col(col)) ofifo_inst (
        .clk(clk),
        .in(mac_array_out),
        .out(ofifo_out),
        .rd(ofifo_rd),
        .wr(mac_array_valid),
        .o_full(ofifo_full),
        .reset(reset),
        .o_ready(ofifo_ready),
        .o_valid(o_valid)
    );

    // MAC Array
    mac_array #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_inst (
        .clk(clk),
        .reset(reset),
        .out_s(mac_array_out),
        .in_w(l0_fifo_out),
        .in_n(mac_array_in_n),
        .inst_w(inst[1:0]),
        .valid(mac_array_valid)
    );

    sfp #(.bw(psum_bw), .col(col)) sfp_row  (
        .clk(clk),
        .reset(reset),
        .in(sfp_in),
        .out(sfp_out)
    );
    // Output
    //assign psum_out = ofifo_out;
    //assign o_ready = l0_fifo_ready;

endmodule
