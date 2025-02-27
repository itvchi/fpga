module consumer (
    input clk,
    input rst_n,
    input s_tvalid,
    input [7:0] s_tdata,
    output s_tready);

reg [7:0] counter;
reg [7:0] tdata;

always @(posedge clk) begin
    if (!rst_n) begin
        tdata <= 8'd0;
    end else begin
        if (s_tvalid && s_tready) begin
            tdata <= s_tdata;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        counter <= 8'd0;
    end else begin
        if (s_tready) begin
            counter <= 8'd0;
        end else begin
            counter <= counter + 1;
        end
    end
end

/* Randomized read fleet validation based on previous s_tdata value (up to 16 counter cycles) */
assign s_tready = (counter[3:0] == tdata[3:0]);

endmodule