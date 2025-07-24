module crc32 (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [3:0] addr,
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o
);

    /* Registers */
    reg [31:0]      r_config;       /* offset: 0x00  RW */
    reg [31:0]      r_polynomial;   /* offset: 0x04  RW */
    reg [31:0]      r_crc_value;    /* offset: 0x0C  RW */

    wire            config_reset = r_config[0];
    wire            config_enable = r_config[1];
    wire            config_width_sel = r_config[3:2];

    /* Address decoding */
    localparam ADDR_CONFIG = 'h0;
    localparam ADDR_POLY   = 'h4;
    localparam ADDR_DATA   = 'h8;
    localparam ADDR_CRC    = 'hC;

    // CRC calculation function
    function [31:0] crc32_update;
        input [31:0] crc_in;
        input [31:0] data_in;
        input [1:0]  width_sel;
        input [31:0] poly;
        integer i, j;
        integer num_bytes;
        reg [7:0] byte;
        reg [31:0] crc;
    begin
        crc = crc_in;
        num_bytes = (width_sel == 2'b00) ? 1 :
                (width_sel == 2'b01) ? 2 :
                (width_sel == 2'b10) ? 4 : 1;

        for (i = 0; i < num_bytes; i = i + 1) begin
            byte = (data_in >> (8 * i)) & 8'hFF;
            for (j = 0; j < 8; j = j + 1) begin
                if ((crc[31] ^ byte[7 - j]) == 1'b1)
                    crc = (crc << 1) ^ poly;
                else
                    crc = (crc << 1);
            end
        end
        crc32_update = crc;
    end
    endfunction

    always @(posedge clk) begin
        if (!reset_n) begin
            r_config <= 32'b0;
            r_polynomial <= 32'h04C11DB7;
            r_crc_value <= 32'hFFFFFFFF;
            ready <= 1'b0;
        end else begin
            ready <= 1'b0;

            if (select) begin
                if (wstrb == 'd0) begin
                    case (addr)
                        ADDR_CONFIG: data_o <= r_config;
                        ADDR_POLY:   data_o <= r_polynomial;
                        ADDR_DATA:   data_o <= 32'b0;
                        ADDR_CRC:    data_o <= (r_crc_value ^ 32'hFFFFFFFF);
                    endcase
                end else begin
                    case (addr)
                        ADDR_CONFIG: r_config <= data_i;
                        ADDR_POLY: r_polynomial <= data_i;
                        ADDR_DATA: begin
                            if (config_enable) begin
                                r_crc_value <= crc32_update(r_crc_value, data_i, config_width_sel, r_polynomial);
                            end
                        end
                    endcase
                end
                ready <= 1'b1;
            end
            if (config_reset) begin
                r_config <= 32'b0;
                r_polynomial <= 32'h04C11DB7;
                r_crc_value <= 32'hFFFFFFFF;
            end else if (config_enable) begin

            end
        end
    end
endmodule
