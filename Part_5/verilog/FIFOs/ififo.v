module IFIFO #(
    parameter bw = 4,
    parameter depth = 8
)(
    input clk,
    input reset,
    input wr_en,
    input [bw-1:0] data_in,
    output reg [bw-1:0] data_out,
    output reg full,
    output reg empty
);

    reg [bw-1:0] fifo_mem [0:depth-1];
    reg [bw-1:0] read_ptr, write_ptr;
    reg [bw-1:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            read_ptr <= 0;
            write_ptr <= 0;
            count <= 0;
            full <= 0;
            empty <= 1;
        end else begin
            // Write logic
            if (wr_en && !full) begin
                fifo_mem[write_ptr] <= data_in;
                write_ptr <= (write_ptr + 1) % depth;
                count <= count + 1;
            end

            // Read logic
            if (!empty) begin
                data_out <= fifo_mem[read_ptr];
                read_ptr <= (read_ptr + 1) % depth;
                count <= count - 1;
            end

            // Update status
            full <= (count == depth);
            empty <= (count == 0);
        end
    end
endmodule
