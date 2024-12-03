module corelet #(
    parameter bw = 8,
    parameter psum_bw = 16,
    parameter row = 8,
    parameter col = 8
)(
    input wire clk,
    input wire reset,
    input wire [bw*row-1:0] activation_in,
    input wire [bw*row-1:0] weight_in,
    output wire [psum_bw*col-1:0] corelet_out,
    output wire o_ready,
    output wire o_valid,
    input wire [6:0] inst
);

    // Internal signals
    wire [psum_bw*col-1:0] mac_array_out;
    wire [col-1:0] mac_array_valid;
    wire l0_fifo_full, l0_fifo_ready;
    wire [bw*row-1:0] l0_fifo_out;
    wire ofifo_full, ofifo_ready, ofifo_valid;
    wire [psum_bw*col-1:0] ofifo_out;
    wire [bw*row-1:0] ififo_out;

    wire ofifo_rd;
    wire ififo_wr;
    wire ififo_rd;
    wire l0_rd;
    wire l0_wr;

    assign ofifo_rd = inst[6];
    assign ififo_wr = inst[5];
    assign ififo_rd = inst[4];
    assign l0_rd = inst[3];
    assign l0_wr = inst[2];

    assign corelet_out = ofifo_out;
    
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

    // IFIFO for weight data
    ififo #(.bw(bw), .row(row)) ififo_inst (
        .clk(clk),
        .in(weight_in),
        .out(ififo_out),
        .wr(ififo_wr),
        .rd(ififo_rd),
        .o_full(),
        .reset(reset)
    );

    // MAC Array
    mac_array #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_inst (
        .clk(clk),
        .reset(reset),
        .out_s(mac_array_out),
        .in_w(ififo_out),
        .in_n(l0_fifo_out),
        .inst_w(inst[1:0]),
        .valid(mac_array_valid)
    );

endmodule
