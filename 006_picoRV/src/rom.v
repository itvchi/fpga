module rom (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [1:0]  addr,
    input [31:0]  data_i,
    output reg ready,
    output reg [31:0] data_o
);

    reg [31:0] mem [3:0];

    initial begin
        /* Execute code from SRAM */
        mem[0] = 32'h000202b7; // lui t0, 0x20
        mem[1] = 32'h00028067; // jalr zero, 0(t0)
        mem[2] = 32'h0;
        mem[3] = 32'h0;
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            mem[0] <= 32'h000202b7; // lui t0, 0x20
            mem[1] <= 32'h00028067; // jalr zero, 0(t0)
            mem[2] <= 32'h0;
            mem[3] <= 32'h0;
        end else begin
            if (select) begin
                if (wstrb == 4'b0000) begin
                    data_o <= mem[addr[1:0]];
                end else begin
                    /* ROM is NOT writable */
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