module rom (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [9:0]  addr,
    input [31:0]  data_i,
    output reg ready,
    output reg [31:0] data_o
);

    reg [31:0] mem [1023:0];

    initial begin
        $readmemh("mem_files/rom.hex", mem);
    end

    always @(posedge clk) begin
        if (select) begin
            if (wstrb == 4'b0000) begin
                data_o <= mem[addr[9:0]];
            end else begin
                /* ROM is NOT writable */
            end
        end
    end

    /* ready signal have to be delayed one cycle according to select,
        otherwise the CPU is not working */
    always @(posedge clk) begin
        ready <= select;
    end

endmodule