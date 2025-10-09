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
            if (counter >= (prescaler + 2)) begin
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