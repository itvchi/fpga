module uart_tx (
    input clk,
    input clk_en,
    input rst_n,
    input start,
    input [7:0] data,
    output reg tx,
    output busy);

localparam 
STATE_IDLE = 3'd0,
STATE_READY = 3'd1,
STATE_START_BIT = 3'd2,
STATE_DATA_BIT = 3'd3,
STATE_STOP_BIT = 3'd4,
STATE_WAIT = 3'd5;

reg [2:0] current_state;
reg [2:0] next_state;
reg [2:0] state_counter;
reg [7:0] tx_data;

/* next_state combinational block */
always @(*) begin
    next_state = current_state;
    case (current_state)
        STATE_IDLE: begin
            if (start) begin
                next_state <= STATE_READY;
            end
        end
        STATE_READY: begin
            // if (clk_en) begin
                next_state <= STATE_START_BIT;
            // end
        end
        STATE_START_BIT: begin
            next_state <= STATE_DATA_BIT;
        end
        STATE_DATA_BIT: begin
            if (state_counter == 7) begin
                next_state <= STATE_STOP_BIT;
            end
        end
        STATE_STOP_BIT: begin
            next_state <= STATE_WAIT;
        end
        STATE_WAIT: begin
            next_state <= STATE_IDLE;
        end
    endcase
end

/* current_state synchronous block */
always @(posedge clk) begin
    if (!rst_n) begin
        current_state <= STATE_IDLE;
    end else begin
        if (next_state == STATE_READY || clk_en) begin
            current_state <= next_state;
        end
    end
end

/* Latch data at STATE_READY */
always @(posedge clk) begin
	if (!rst_n) begin
            tx_data <= 8'd0;
	end else begin
        if (next_state == STATE_READY && current_state != next_state) begin
            tx_data <= data;
        end
	end
end

/* state_counter synchronous block */
always @(posedge clk) begin
    if (!rst_n) begin
        state_counter <= 3'd0;
    end else begin
        if (clk_en) begin
            if (current_state != next_state) begin
                state_counter <= 3'd0;
            end else begin
                state_counter <= state_counter + 3'd1;
            end
        end
    end
end

localparam
TX_IDLE = 1'b1,
TX_START = 1'b0,
TS_STOP = 1'b1;

/* tx output logic */
always @(*) begin
    case (current_state)
        STATE_IDLE:         tx = TX_IDLE;
        STATE_READY:        tx = TX_IDLE;
        STATE_START_BIT:    tx = TX_START;
        STATE_DATA_BIT:     tx = tx_data[state_counter];
        STATE_STOP_BIT:     tx = TS_STOP;
        STATE_WAIT:         tx = TX_IDLE;
    endcase
end

assign busy = (current_state != STATE_IDLE);

endmodule