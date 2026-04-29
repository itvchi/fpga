module i2c_fifo(
    input clk,
    inout sda,
    input scl,
    output [3:0] hw_dbg
);

wire n_rst;

reset rst(
    .clk(clk),
    .n_rst(n_rst)
);

reg wr_en;
wire [7:0] data_out;

wire i2c_reg_wr;
wire [7:0] i2c_reg_wr_addr;
wire i2c_reg_rd;
wire [7:0] i2c_reg_rd_addr;

wire [7:0] set_addr_reg; /* Addr: 0x00 */ 
reg [7:0] curr_addr_reg; /* Addr: 0x01 */
wire [7:0] set_data_reg; /* Addr: 0x02 */
reg [7:0] read_data_reg; /* Addr: 0x03 */

bram #(
    .DEPTH(64)
) bram_mem (
    .clk(clk),
    .wr_en(wr_en),
    .addr(curr_addr_reg),
    .data_in(set_data_reg),
    .data_out(data_out)
);

i2cSlave u_i2cSlave(
    .clk(clk),
    .rst(~n_rst),
    .sda(sda),
    .scl(scl),
    .i2c_reg_wr(i2c_reg_wr),
    .i2c_reg_wr_addr(i2c_reg_wr_addr),
    .i2c_reg_rd(i2c_reg_rd),
    .i2c_reg_rd_addr(i2c_reg_rd_addr),
    .myReg0(set_addr_reg),
    .myReg1(curr_addr_reg),
    .myReg2(set_data_reg),
    .myReg3(read_data_reg)
);

always @(posedge clk) begin
    wr_en <= 1'b0;

    if (i2c_reg_wr) begin
        if (i2c_reg_wr_addr == 8'h00) begin
            curr_addr_reg <= set_addr_reg; /* Update curr_addr_reg during set_addr_reg write */
        end else if (i2c_reg_wr_addr == 8'h02) begin
            wr_en <= 1'b1; /* Assert wr_en during write into set_data_reg - data will be written into bram in next clock */
        end
    end
    if (wr_en) begin
        curr_addr_reg <= curr_addr_reg + 8'd1; /* Increment curr_addr_reg when write operation performed */
    end
    if (i2c_reg_rd) begin
        if (i2c_reg_rd_addr == 8'h03) begin
            read_data_reg <= data_out; /* Update read_data_reg with data @addr in curr_addr_reg */
            curr_addr_reg <= curr_addr_reg + 8'd1; /* Update curr_addr_reg for next access (write/read) */
        end
    end
end

assign hw_dbg[0] = scl;
assign hw_dbg[1] = sda;
assign hw_dbg[2] = i2c_reg_wr;
assign hw_dbg[3] = i2c_reg_rd;

endmodule