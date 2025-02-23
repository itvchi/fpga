module producer (
    input clk,
    input rst_n,
    input m_tready,
    output [31:0] m_tdata,
    output m_tvalid);

reg [31:0] tdata;
reg tvalid;

always @(posedge clk) begin
    if (!rst_n) begin
        tdata <= 32'd0;
        tvalid <= 1'b0;
    end else begin
        if (!tvalid) begin
            tdata <= $urandom%4096;
            tvalid <= 1'b1;
        end
        if (m_tready) begin
            tdata <= $urandom%4096;
            tvalid <= 1'b1;
        end
    end
end

assign m_tdata = tdata;
assign m_tvalid = tvalid;

endmodule