module core #(
    parameter bw = 4,
    parameter psum_bw = 16,
    parameter row = 8,
    parameter col = 8
)(
    input wire clk,
    input wire reset,
    input wire [row*bw-1:0] D_xmem,
    input wire [33:0] inst,
    output wire [col*psum_bw-1:0] sfp_out,
    output wire ofifo_valid
);

    wire [row*bw-1:0] xmem_out;
    wire [row*bw-1:0] act_in, weight_in;
    wire [col*psum_bw-1:0] corelet_out, pmem_in, pmem_out, sfp_in, sfp_out_temp;

    wire CEN_xmem, CEN_pmem;
    wire WEN_xmem, WEN_pmem;
    wire [10:0] xmem_addr, pmem_addr;

    assign xmem_addr = inst[17:7];
    assign pmem_addr = inst[30:20];
    assign CEN_xmem = inst[19];
    assign WEN_xmem = inst[18];
    assign CEN_pmem = inst[32];
    assign WEN_pmem = inst[31];

    assign act_in = xmem_out;
    assign pmem_in = inst[33] ? sfp_out_temp : corelet_out;  // If accumulation, use sfp; else corelet_out
    assign sfp_out = sfp_out_temp;
    assign ofifo_valid = o_valid;

    // Instantiate SRAM for activations
    sram #(.bw(row*bw)) xmem_sram (
        .CLK(clk),
        .D(D_xmem),
        .Q(xmem_out),
        .CEN(CEN_xmem),
        .WEN(WEN_xmem),
        .A(xmem_addr)
    );

    // Instantiate SRAM for output
    sram #(.bw(col*psum_bw)) pmem_sram (
        .CLK(clk),
        .D(pmem_in),
        .Q(pmem_out),
        .CEN(CEN_pmem),
        .WEN(WEN_pmem),
        .A(pmem_addr)
    );

    // Instantiate corelet
    corelet #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) corelet_inst (
        .clk(clk),
        .reset(reset),
        .inst(inst[6:0]),
        .activation_in(act_in),
        .weight_in(weight_in),
        .corelet_out(corelet_out),
        .o_valid(o_valid)
    );

    // Instantiate sfp
    sfp #(.bw(psum_bw), .col(col)) sfp_row (
        .clk(clk),
        .reset(reset),
        .in(sfp_in),
        .out(sfp_out_temp)
    );

endmodule
