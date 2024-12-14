module sfp #(
    parameter bw = 16,
    parameter col = 8
)(
    input clk,
    input reset,
    input [bw*col-1:0] in, // from ofifo
    input [bw*col-1:0] in_pmem, // from pmsm
    input en_relu,
    output reg [bw*col-1:0] out
);

    reg [bw*col-1:0] acc = 0;
    reg [bw*col-1:0] in_old = 0;

    

    genvar i;
    generate
        for (i = 0; i < col; i = i + 1) begin : relu_acc_gen
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    out[bw*(i+1)-1 : bw*i] <= 0;
                    acc[bw*(i+1)-1 : bw*i] <= 0;
                    in_old[bw*(i+1)-1 : bw*i] <= 0;
                end else begin
                    in_old[bw*(i+1)-1 : bw*i] <= in[bw*(i+1)-1 : bw*i];
                    acc[bw*(i+1)-1 : bw*i] = $signed(in_old[bw*(i+1)-1 : bw*i]) + $signed(in_pmem[bw*(i+1)-1 : bw*i]);
                    if (en_relu) begin // only for calculating final out;
                        out[bw*(i+1)-1 : bw*i] <= ($signed(acc[bw*(i+1)-1 : bw*i]) < 0) ? 0 : (acc[bw*(i+1)-1 : bw*i] >> 1);
                    end else begin // for accumualtion
                        out[bw*(i+1)-1 : bw*i] <= acc[bw*(i+1)-1 : bw*i];
                    end
                end
            end
        end
    endgenerate

endmodule

