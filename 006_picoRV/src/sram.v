module sram #(parameter ADDRWIDTH=13) (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [ADDRWIDTH-1:0] addr,
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o);  

wire [ADDRWIDTH-3:0] word_addr;
assign word_addr = addr[ADDRWIDTH-1:2];

reg [31:0] mem [2047:0];

integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1) begin
        mem[i] = 32'd0; 
        mem[i + 1024] = 32'd0;
    end
end

always @(posedge clk) begin
    if (select) begin
        if (wstrb == 4'b0000) begin
            data_o <= mem[word_addr];
        end else begin
            if (wstrb[0]) begin
                mem[word_addr][7:0] <= data_i[7:0];
            end
            if (wstrb[1]) begin
                mem[word_addr][15:8] <= data_i[15:8];
            end
            if (wstrb[2]) begin
                mem[word_addr][23:16] <= data_i[23:16];
            end
            if (wstrb[3]) begin
                mem[word_addr][31:24] <= data_i[31:24];
            end
        end
    end
end

/* ready signal have to be delayed one cycle according to select,
    otherwise the CPU is not working */
always @(posedge clk) begin
    ready <= select;
end

endmodule // sram