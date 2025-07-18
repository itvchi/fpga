module user_flash_custom (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [14:0]  addr,
    input [31:0]  data_i,
    output reg ready,
    output reg [31:0] data_o,
    output reg cache_hit,
    output reg cache_miss
);

    reg [31:0] mem [8191:0];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 32'd0; 
            mem[i + 1024] = 32'd0; 
            mem[i + 2048] = 32'd0; 
            mem[i + 3072] = 32'd0; 
            mem[i + 4096] = 32'd0; 
            mem[i + 5120] = 32'd0; 
            mem[i + 6144] = 32'd0; 
            mem[i + 7168] = 32'd0; 
        end
    end

    always @(posedge clk) begin
        if (select) begin
            if (wstrb == 4'b0000) begin
                data_o <= mem[addr[14:0]];
            end else begin
                /* Mock flash is writable, to load by bootloader */
                if (wstrb[0]) begin
                    mem[addr[14:0]][7:0] <= data_i[7:0];
                end
                if (wstrb[1]) begin
                    mem[addr[14:0]][15:8] <= data_i[15:8];
                end
                if (wstrb[2]) begin
                    mem[addr[14:0]][23:16] <= data_i[23:16];
                end
                if (wstrb[3]) begin
                    mem[addr[14:0]][31:24] <= data_i[31:24];
                end
            end
        end
    end

    /* ready signal have to be delayed one cycle according to select,
        otherwise the CPU is not working */
    always @(posedge clk) begin
        ready <= select;
    end

endmodule