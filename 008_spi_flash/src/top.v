module top (
    input clk,
    input rst_btn_n,
    output spi_cs,
    output spi_clk,
    output spi_mosi);

reg [11:0] rst_counter = 0;
wire rst_n;

always @(posedge clk) begin
    if (rst_counter[11] == 0) begin
        rst_counter <= rst_counter + 12'd1;
    end else if (!rst_btn_n) begin
        rst_counter <= 12'd0;
    end
end

assign rst_n = rst_counter[11];

reg [7:0] data;
reg valid;
reg [31:0] counter;
wire ready;
reg [1:0] ready_counter;

/* Values are selected experimentally to test one byte transfer, then burst transfer */
always @(posedge clk) begin
    if (!rst_n) begin
        data <= 8'd0;
        valid <= 1'b0;
        counter <= 32'd0;
        ready_counter <= 2'd0;
    end else begin
        counter <= counter + 32'd1;

        if (counter == 1000) begin
            valid <= 1'b1;
            data <= 8'hA5;
        end else begin
            if (!ready && valid) begin
                valid <= 1'b0;
            end

            if (counter > 1300) begin
                if (ready && valid) begin
                    ready_counter <= ready_counter + 2'd1;
                end
                if (ready_counter == 3) begin
                    valid <= 1'b0;
                end else begin
                    valid <= 1'b1;
                    data <= 8'h2C;
                end
            end
        end
    end
end

spi_master spi (
    .clk(clk),
    .rst_n(rst_n),
    .data(data),
    .valid(valid),
    .ready(ready),
    .spi_cs(spi_cs),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi));

endmodule