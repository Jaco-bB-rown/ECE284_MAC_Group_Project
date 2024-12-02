module sfp #(
    parameter bw = 4,
    parameter col = 8
)(
    input clk,
    input reset,
    input [bw*col-1:0] in,
    output reg [bw*col-1:0] out
);

    genvar i;
    generate
        for (i = 0; i < col; i = i + 1) begin : relu_gen
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    out[bw*(i+1)-1 : bw*i] <= 0;
                end else begin
                    out[bw*(i+1)-1 : bw*i] <= (in[bw*(i+1)-1] == 1'b1) ? 0 : in[bw*(i+1)-1 : bw*i];
                end
            end
        end
    endgenerate

endmodule
