module spi_flash_controller (
    input clk,
    input rst_n,
    input [23:0] req_address,
    input [7:0] req_size, /* not used yet */
    input req_valid,
    output req_ready,
    output spi_cs,
    output spi_clk,
    output spi_mosi);

// Internal signals
reg [3:0] current_state, next_state;

reg [7:0] data = 8'hAC;
reg       valid;
// wire       valid;
wire      ready;

assign req_ready = (current_state == STATE_IDLE);

reg [23:0] address;
reg [2:0] address_counter;
reg [7:0] size;
reg [7:0] data_counter;


// State encoding
localparam 
STATE_RESET         = 4'd0,
STATE_RESET_WAIT    = 4'd1,
STATE_PWRUP         = 4'd2,
STATE_PWRUP_WAIT    = 4'd3,
STATE_IDLE          = 4'd4,
STATE_CMD_READ      = 4'd6,
STATE_ADDRESS       = 4'd7,
STATE_DATA          = 4'd8,
STATE_WAIT_CS       = 4'd9;

// State register
always @(posedge clk) begin
    if (!rst_n)
        current_state <= STATE_RESET;
    else
        current_state <= next_state;
end

// Next state logic
always @(*) begin
    case (current_state)
        STATE_RESET: next_state = (valid && ready) ? STATE_RESET_WAIT : STATE_RESET;
        STATE_RESET_WAIT: next_state = spi_cs ? STATE_PWRUP : STATE_RESET_WAIT;
        STATE_PWRUP: next_state = (valid && ready) ? STATE_PWRUP_WAIT : STATE_PWRUP;
        STATE_PWRUP_WAIT: next_state = spi_cs ? STATE_IDLE : STATE_PWRUP_WAIT;
        STATE_IDLE: next_state = (req_valid && req_ready) ? STATE_CMD_READ : STATE_IDLE;
        STATE_CMD_READ: next_state = (valid && ready) ? STATE_ADDRESS : STATE_CMD_READ;
        STATE_ADDRESS: next_state = (address_counter == 3) ? STATE_DATA : STATE_ADDRESS;
        STATE_DATA: next_state = (data_counter == size) ? STATE_WAIT_CS : STATE_DATA;
        STATE_WAIT_CS: next_state = spi_cs ? STATE_IDLE : STATE_WAIT_CS;
        default: next_state = STATE_IDLE;
    endcase
end

always @(posedge clk) begin
    if (!rst_n) begin
        address_counter <= 3'd0;
        data_counter <= 8'd0;
    end else begin
        if (current_state == STATE_ADDRESS && valid && ready) begin
            address_counter <= address_counter + 3'd1;
        end
        if (current_state == STATE_DATA && valid && ready) begin
            data_counter <= data_counter + 7'd1;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        address <= 24'd0;
    end else begin
        if (req_valid && req_ready) begin
            address <= req_address;
            size <= req_size;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        data <= 8'd0;
        valid <= 1'b0;
    end else begin
        if (current_state == STATE_RESET) begin
            data <= 8'HFF;
            valid <= 1'b1;
        end else if (current_state == STATE_PWRUP) begin
            data <= 8'HAB;
            valid <= 1'b1;
        end else if (current_state == STATE_CMD_READ) begin
            data <= 8'H03;
            valid <= 1'd1;
        end else if (current_state == STATE_ADDRESS) begin
            data <= address[23 - 8*address_counter -: 8];
            valid <= 1'd1;
        end else if (current_state == STATE_DATA) begin
            data <= 8'h00;
            valid <= 1'd1;
        end else begin
            valid <= 1'b0;
        end
    end
end

spi_master spi_inst (
    .clk(clk),
    .rst_n(rst_n),
    .spi_cs(spi_cs),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .data(data),
    .valid(valid),
    .ready(ready)
);

endmodule
