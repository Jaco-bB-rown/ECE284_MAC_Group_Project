module pe #(
    parameter bw = 4,
    parameter psum_bw = 16
)(
    input clk,
    input reset,
    input mode,                   // 1 for weight-stationary, 0 for output-stationary
    input [bw-1:0] input_data,
    input [bw-1:0] weight_data,
    input input_valid,
    input weight_valid,
    output reg [psum_bw-1:0] psum,
    output reg valid_out
);

    reg [bw-1:0] weight_reg;
    reg [psum_bw-1:0] psum_reg;
    wire [psum_bw-1:0] mult_result;

    // Multiply input and weight
    assign mult_result = input_data * weight_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            psum <= 0;
            psum_reg <= 0;
            weight_reg <= 0;
            valid_out <= 0;
        end else begin
            if (mode) begin
                // Weight-stationary mode
                if (weight_valid) weight_reg <= weight_data;
                if (input_valid) begin
                    psum_reg <= psum_reg + mult_result;
                    valid_out <= 1;
                end
            end else begin
                // Output-stationary mode
                if (input_valid) begin
                    weight_reg <= weight_data;
                    psum <= psum + mult_result;
                    valid_out <= 1;
                end
            end
        end
    end
endmodule
