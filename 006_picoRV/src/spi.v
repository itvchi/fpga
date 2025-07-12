module spi_master #(
    parameter CLK_FREQ = 27000000,
    parameter SPI_FREQ = 1500000,
    parameter CPOL = 0,
    parameter CPHA = 1
) (
    input clk,
    input rst_n,
    /* Data stream interface from driver */
    input [7:0] data,
    input valid,
    output ready,
    /* SPI signals */
    output spi_cs,
    output spi_clk,
    output spi_mosi);

localparam integer CLK_DIV = (CLK_FREQ / (SPI_FREQ * 2));
localparam DEFAULT_BITCOUNT = CPHA ? 4'hF : 4'h0;

reg [7:0] local_data;
reg [7:0] shift_reg;
reg local_ready;
reg [3:0] bitcount;

localparam
STATE_IDLE = 4'b0001,
STATE_SEND = 4'b0010,
STATE_DONE = 4'b0100,
STATE_WAIT = 4'b1000;

reg [3:0] current_state;
reg [3:0] next_state;

/* Register next_state into current_state */
always @(posedge clk) begin
    if (!rst_n) begin
        current_state <= STATE_IDLE;
    end else begin
        current_state <= next_state;
    end
end

/* Current state cobinational logic */
always @(*) begin
    next_state = current_state;
    case (current_state)
        STATE_IDLE: next_state = valid ? STATE_SEND : STATE_IDLE;
        STATE_SEND: next_state = (bitcount == 4'd7 && clk_en) ? STATE_DONE : STATE_SEND;
        STATE_DONE: next_state = valid ? STATE_WAIT : (clk_en ? STATE_IDLE : STATE_DONE);
        STATE_WAIT: next_state = clk_en ? STATE_SEND : STATE_WAIT;
        default: next_state = STATE_IDLE;
    endcase
end

always @(posedge clk) begin
    if (!rst_n) begin
        local_data <= 1'b0;
    end else begin
        if (valid && local_ready) begin
            local_data <= data;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bitcount <= DEFAULT_BITCOUNT;
    end else if (clk_en) begin
        if (current_state != STATE_SEND && next_state != STATE_SEND) begin
            bitcount <= DEFAULT_BITCOUNT;  // Reset when not sending
        end else if (second_edge) begin // Increment on the correct SPI clock edge based on CPHA
            bitcount <= (bitcount + 4'd1) & 4'h7;
        end
    end
end

/* local_ready sequential logic */
always @(posedge clk) begin
    if (!rst_n) begin
        local_ready <= 1'b0;
    end else begin
        local_ready <= !(next_state == STATE_SEND || next_state == STATE_WAIT); /* Not ready during SEND and WAIT (before next SEND) */
    end
end

reg [31:0] clk_counter;
reg clk_en;

always @(posedge clk) begin
    if (!rst_n) begin
        clk_counter <= 32'd0;
        clk_en <= 1'b0;
    end else begin
        if (current_state != STATE_IDLE) begin
            if (clk_counter >= (CLK_DIV - 1)) begin
                clk_counter <= 32'd0;
                clk_en <= 1'b1;
            end else begin
                clk_counter <= clk_counter + 32'd1;
                clk_en <= 1'b0;
            end
        end else begin
            clk_counter <= 32'd0;
            clk_en <= 1'b0;
        end
    end
end


reg local_spi_clk;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        local_spi_clk <= 1'b0;
    end else if (next_state == STATE_IDLE) begin
        local_spi_clk <= CPOL;  /* Hold CPOL in IDLE */
    end else if (clk_en && (current_state == STATE_SEND || next_state == STATE_SEND)) begin
        local_spi_clk <= ~local_spi_clk;  /* Toggle only when clk_en is asserted and during SEND state */
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        shift_reg <= 8'b0;
    end else begin 
        if (next_state != current_state && next_state == STATE_SEND) begin
            shift_reg <= (valid && local_ready) ? data : local_data; /* Load new byte when ready - from stream or latched before to local_data */
        end
        if (current_state == STATE_SEND) begin
            if (clk_en && (bitcount != DEFAULT_BITCOUNT || CPHA == 0) && second_edge) begin
                shift_reg <= {shift_reg[6:0], 1'b0};  // Shift left
            end
    end
    end
end

wire second_edge;
assign second_edge = CPHA ? ((CPOL == 0 && !local_spi_clk) || (CPOL == 1 && local_spi_clk)) : ((CPOL == 0 && local_spi_clk) || (CPOL == 1 && !local_spi_clk));

/* Assign external signals */
assign ready = local_ready;
assign spi_cs = (current_state == STATE_IDLE); /* Deassert in IDLE (active low signal) */
assign spi_clk = local_spi_clk; 
assign spi_mosi = shift_reg[7]; /* MSB-first */

endmodule

module spi (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [3:0] addr,
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o,
    output spi_cs,
    output spi_clk,
    output spi_mosi);

reg [31:0]      r_config;       /* offset: 0x00  RW */
reg [31:0]      r_prescaler;    /* offset: 0x04  RW */
reg [31:0]      r_status;       /* offset: 0x08  RW */
reg [7:0]       r_tx_data;      /* offset: 0x0C  W  */

wire            config_reset = r_config[0];
wire            config_enable = r_config[1];
wire            config_send = r_config[2];
wire            status_busy = r_status[0];

reg new_tx_data;
reg [7:0] spi_tx_data;
reg start;
wire spi_ready;

spi_master master (
    .clk(clk),
    .rst_n(reset_n),
    .data(spi_tx_data),
    .valid(start),
    .ready(spi_ready),
    .spi_cs(spi_cs),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi));

initial begin
    r_config <= 32'd0;
    r_prescaler <= 32'd0;
    r_status <= 32'd0;
    r_tx_data <= 8'd0;

    start <= 1'b0;
    spi_tx_data <= 8'd0;
    new_tx_data <= 1'b0;
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        r_config <= 32'd0;
        r_prescaler <= 32'd0;
        r_status <= 32'd0;
        r_tx_data <= 8'd0;

        start <= 1'b0;
        spi_tx_data <= 8'd0;
        new_tx_data <= 1'b0;

        ready <= 1'b0;
    end else begin
        ready <= 1'b0;
        r_config <= r_config;
        r_status <= r_status;

        if (select) begin
            if (wstrb == 'd0) begin
                case (addr)
                    8'h00:  data_o <= r_config;
                    8'h04:  data_o <= r_prescaler;
                    8'h08:  data_o <= r_status;
                    8'h0C:  data_o <= 32'd0;
                endcase
            end else begin
                case (addr)
                    8'h00:  r_config <= data_i;
                    8'h04:  r_prescaler <= data_i;
                    8'h08:  r_status <= data_i;
                    8'h0C:  begin
                        r_tx_data <= data_i[7:0];
                        new_tx_data <= 1'b1;
                    end
                endcase
            end
            ready <= 1'b1;
        end
        
        if (config_reset) begin
            r_config <= 32'd0;
            r_prescaler <= 32'd0;
            r_status <= 32'd0;
            r_tx_data <= 32'd0;

            start <= 1'b0;
            spi_tx_data <= 8'd0;
            new_tx_data <= 1'b0;
        end else if (config_enable) begin
            /* Set tx busy bit in r_status register - set and reset by hardware */
            if (!spi_ready) begin
                r_status[0] <= 1'b1;
            end else begin
                r_status[0] <= 1'b0;
            end

            /* Handle start pulse on data write to tx register */
            if (new_tx_data && spi_ready) begin
                spi_tx_data <= r_tx_data;
                new_tx_data <= 1'b0;
                start <= 1'b1;
            end else begin
                start <= 1'b0;
            end
        end
    end
end

endmodule