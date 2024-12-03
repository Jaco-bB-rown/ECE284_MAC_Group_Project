module pe_array #(
    parameter bw = 8,
    parameter psum_bw = 16,
    parameter row = 8,
    parameter col = 8
)(
    input clk,
    input reset,
    input mode,
    input [bw-1:0] input_data [0:row-1],
    input [bw-1:0] weight_data [0:col-1],
    input input_valid,
    input weight_valid,
    output [psum_bw-1:0] output_data [0:row-1],
    output valid_out
);

    genvar i, j;
    wire [psum_bw-1:0] pe_outputs [0:row-1][0:col-1];
    wire pe_valids [0:row-1][0:col-1];

    generate
        for (i = 0; i < row; i = i + 1) begin : row_gen
            for (j = 0; j < col; j = j + 1) begin : col_gen
                PE #(
                    .bw(bw),
                    .psum_bw(psum_bw)
                ) pe_inst (
                    .clk(clk),
                    .reset(reset),
                    .mode(mode),
                    .input_data(input_data[i]),
                    .weight_data(weight_data[j]),
                    .input_valid(input_valid),
                    .weight_valid(weight_valid),
                    .psum(pe_outputs[i][j]),
                    .valid_out(pe_valids[i][j])
                );
            end
        end
    endgenerate

    // Aggregate outputs and valid signals
    assign output_data = pe_outputs[0];
    assign valid_out = pe_valids[0][0];
endmodule
