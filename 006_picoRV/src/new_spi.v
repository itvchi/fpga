module spi_master (
    input clk,
    input rst_n,
    input [7:0] prescaler,
    input cpol,
    input cpha,
    /* Data stream interface from driver */
    input [7:0] tx_data,
    input tx_valid,
    output tx_ready,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output busy,
    /* SPI signals */
    output spi_cs,
    output spi_clk,
    output spi_mosi,
    input spi_miso);

/* Configuration registers - latched when no transaction is pending */
reg [7:0] PRESCALER;
reg CPOL, CPHA;
reg [3:0] DEFAULT_BITCOUNT;

always @(posedge clk) begin
    if (!rst_n) begin
        PRESCALER <= 8'b0;
        CPOL <= 1'b0;
        CPHA <= 1'b0;
        DEFAULT_BITCOUNT <= 4'b0;
    end else if (current_state == STATE_IDLE && next_state == STATE_IDLE) begin
        PRESCALER <= prescaler;
        CPOL <= cpol;
        CPHA <= cpha;
        DEFAULT_BITCOUNT <= cpha ? 4'hF : 4'h0;
    end
end

/* State machine */
localparam
STATE_IDLE = 3'b001,       // no transaction
STATE_TRANSFER = 3'b010,   // shift bits
STATE_BYTE_DONE = 3'b100;  // one byte finished, check next

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

/* Clock enable signal generator */
wire clk_en;

clk_en_gen #(
        .COUNTER_WIDTH(8)
    ) clock_enable (
        .clk(clk), 
        .rst_n(rst_n),
        .enable(current_state != STATE_IDLE),
        .prescaler(PRESCALER),
        .clk_en(clk_en));

/* Capture tx data */
reg [7:0] data_r;

always @(posedge clk) begin
    if (!rst_n) begin
        data_r <= 1'b0;
    end else begin
        if (tx_valid && tx_ready) begin
            data_r <= tx_data;
        end
    end
end

// compute next spi clock value (based on current spi_clk_r and whether we toggle now)
wire spi_toggle_en = clk_en && (current_state == STATE_TRANSFER);
wire next_spi_clk = (current_state == STATE_IDLE) ? CPOL : (spi_toggle_en ? ~spi_clk_r : spi_clk_r);

wire spi_rising_edge  = ({spi_clk_r, next_spi_clk} == 2'b01);
wire spi_falling_edge = ({spi_clk_r, next_spi_clk} == 2'b10);

// leading/trailing according to CPOL
wire spi_leading_edge  = (CPOL == 1'b0) ? spi_rising_edge  : spi_falling_edge;
wire spi_trailing_edge = (CPOL == 1'b0) ? spi_falling_edge : spi_rising_edge;

// sample/shift edges according to CPHA
wire spi_sample_edge = (CPHA == 1'b0) ? spi_leading_edge  : spi_trailing_edge;
wire spi_shift_edge  = (CPHA == 1'b0) ? spi_trailing_edge : spi_leading_edge;

/* SPI clock */
reg spi_clk_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_clk_r <= CPOL;
    end else if (current_state == STATE_IDLE) begin
        spi_clk_r <= CPOL;
    end else if (clk_en && current_state == STATE_TRANSFER) begin
        spi_clk_r <= ~spi_clk_r;
    end
end

/* Bitcount logic */
reg [3:0] bitcount;

wire start_transfer = ((current_state == STATE_IDLE) || (current_state == STATE_BYTE_DONE)) && tx_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bitcount <= DEFAULT_BITCOUNT;
    end else if (start_transfer) begin
        bitcount <= DEFAULT_BITCOUNT;
    end else if (clk_en && spi_shift_edge) begin
        bitcount <= bitcount + 4'd1;
    end
end

/* Shift-out register */
reg [7:0] shift_out;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_out <= 8'h00;
    end else if (start_transfer) begin
        shift_out <= tx_data;
    end else if (clk_en && spi_shift_edge && bitcount != 4'hF) begin
        shift_out <= {shift_out[6:0], 1'b0};
    end
end

/* Shift-in register */
reg [7:0] shift_in;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_in <= 8'h00;
    end else if (start_transfer) begin
        shift_in <= 8'h00;
    end else if (clk_en && spi_sample_edge) begin
        shift_in <= {shift_in[6:0], spi_miso_r};
    end
end

/* Current state cobinational logic */
always @(*) begin
    next_state = current_state;
    case (current_state)
        STATE_IDLE: next_state = tx_valid ? STATE_TRANSFER : STATE_IDLE;
        STATE_TRANSFER: next_state = (bitcount == 4'd7 && spi_shift_edge && clk_en) ? STATE_BYTE_DONE : STATE_TRANSFER;
        STATE_BYTE_DONE: next_state = tx_valid ? STATE_TRANSFER : (clk_en ? STATE_IDLE : STATE_BYTE_DONE);
        default: next_state = STATE_IDLE;
    endcase
end

/* Capture external signals */
reg [1:0] spi_miso_meta;
wire spi_miso_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_miso_meta <= 2'b00;
    end else begin
        spi_miso_meta <= {spi_miso_meta[0], spi_miso};
    end
end

assign spi_miso_r = spi_miso_meta[1];

/* Assign external signals */
assign tx_ready = (current_state == STATE_IDLE || current_state == STATE_BYTE_DONE);
assign busy = (current_state != STATE_IDLE);

assign spi_cs = (current_state == STATE_IDLE); /* Deassert in IDLE (active low signal) */
assign spi_clk = spi_clk_r; 
assign spi_mosi = shift_out[7]; /* MSB-first */

always @(posedge clk) begin
    rx_valid <= 1'b0; // default assignment

    if (!rst_n) begin
        rx_data <= 8'd0;
    end else begin
        if (current_state != next_state && next_state == STATE_BYTE_DONE) begin
            rx_data <= shift_in;
            rx_valid <= 1'b1;
        end
        if (current_state == STATE_BYTE_DONE) begin
            rx_valid <= 1'b1;
        end
    end
end

endmodule

module clk_en_gen #(
    parameter COUNTER_WIDTH = 16
)(
    input  clk,
    input  rst_n,
    input  enable,
    input  [COUNTER_WIDTH-1:0] prescaler,
    output reg clk_en);

    reg [COUNTER_WIDTH-1:0] counter;

    always @(posedge clk) begin
        clk_en  <= 1'b0; // default assignment

        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else if (enable) begin
            if (counter > (prescaler + 2)) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                clk_en  <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
            end
        end else begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end
    end

endmodule

module spi (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [4:0] addr,
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o,
    output spi_cs,
    output spi_clk,
    output spi_mosi,
    input spi_miso);

reg [31:0]      r_config;       /* offset: 0x00  RW */
reg [31:0]      r_prescaler;    /* offset: 0x04  RW */
reg [31:0]      r_status;       /* offset: 0x08  RW */
reg [7:0]       r_tx_data;      /* offset: 0x0C  W  */
reg [7:0]       r_rx_data;      /* offset: 0x10  R  */

wire            config_reset = r_config[0];
wire            config_enable = r_config[1];
wire            config_cpol = r_config[2];
wire            config_cpha = r_config[3];

wire busy;
reg new_tx_data;
reg [7:0] tx_data;
reg tx_valid;
wire tx_ready;
wire rx_data;
wire rx_valid;

spi_master master (
    .clk(clk),
    .rst_n(reset_n),
    .prescaler(r_prescaler[7:0]),
    .cpol(config_cpol),
    .cpha(config_cpha),
    .tx_data(tx_data),
    .tx_valid(tx_valid),
    .tx_ready(tx_ready),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .busy(busy),
    .spi_cs(spi_cs),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso));

initial begin
    r_config <= 32'd0;
    r_prescaler <= 32'd0;
    r_status <= 32'd0;
    r_tx_data <= 8'd0;
    r_rx_data <= 8'd0;

    tx_valid <= 1'b0;
    tx_data <= 8'd0;
    new_tx_data <= 1'b0;
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        r_config <= 32'd0;
        r_prescaler <= 32'd0;
        r_status <= 32'd0;
        r_tx_data <= 8'd0;

        tx_valid <= 1'b0;
        tx_data <= 8'd0;
        new_tx_data <= 1'b0;

        ready <= 1'b0;
    end else begin
        ready <= 1'b0;
        r_config <= r_config;
        r_status <= r_status;

        if (select) begin
            ready <= 1'b1;
            if (wstrb == 'd0) begin
                case (addr)
                    8'h00:  data_o <= r_config;
                    8'h04:  data_o <= r_prescaler;
                    8'h08:  data_o <= r_status;
                    8'h0C:  data_o <= 32'd0;
                    8'h10:  begin
                        data_o <= {24'd0, r_rx_data};
                        r_status[1] <= 1'b0;
                    end
                endcase
            end else begin
                case (addr)
                    8'h00:  r_config <= data_i;
                    8'h04:  r_prescaler <= data_i;
                    8'h08:  r_status <= data_i;
                    8'h0C:  begin
                        r_tx_data <= data_i[7:0];
                        if (new_tx_data) begin
                            ready <= 1'b0; /* Lock if previous request not handled */
                        end else begin
                            new_tx_data <= 1'b1;
                        end
                    end
                endcase
            end
        end
        
        if (config_reset) begin
            r_config <= 32'd0;
            r_prescaler <= 32'd0;
            r_status <= 32'd0;
            r_tx_data <= 32'd0;

            tx_valid <= 1'b0;
            tx_data <= 8'd0;
            new_tx_data <= 1'b0;
        end else if (config_enable) begin
            /* Set busy bit in r_status register - set and reset by hardware */
            r_status[0] <= busy;

            /* Rewrite data if available and previous were handshaked */
            if (new_tx_data && !tx_valid) begin
                tx_data <= r_tx_data;
                tx_valid <= 1'b1;
            end

            /* Hold tx_valid and lock new_tx_data until tx_data is consumed */
            if (tx_valid && tx_ready) begin
                tx_valid <= 1'b0;
                new_tx_data <= 1'b0;
            end

            if (rx_valid) begin
                r_rx_data <= rx_data;
                r_status[1] <= 1'b1;
            end
        end
    end
end

endmodule