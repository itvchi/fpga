module led_driver(
    input clk,
    input rx,
    output tx,
    output [5:0] leds);

wire [7:0] rx_data;
wire rx_valid;
reg tx_start;
reg [7:0] tx_data;
wire tx_busy;

reg state;
reg [5:0] fsm_leds;

assign leds = ~fsm_leds; /* negation, because of gpio at cathode side */

initial begin
    state <= STATE_IDLE;
    fsm_leds <= 6'b0;
end

localparam
STATE_IDLE = 1'd0,
STATE_SEND = 1'd1;

always @(posedge clk) begin
    tx_start <= 1'b0;

    case (state)
        STATE_IDLE: begin
            if (rx_valid) begin
                if (rx_data > "0" && rx_data <= "6") begin
                    fsm_leds[rx_data - 'h31] = ~fsm_leds[rx_data - 'h31];
                    tx_data <= rx_data;
                end else begin
                    tx_data <= "x";
                end
                state <= STATE_SEND;
            end else begin
                state <= STATE_IDLE;
            end
        end
        STATE_SEND: begin
            tx_start <= 1'b0;

            if (tx_busy) begin
                state <= STATE_SEND;
            end else begin
                tx_start <= 1'b1;
                state <= STATE_IDLE;
            end
        end
        default: begin
            state <= STATE_IDLE;
        end
    endcase
end

uart #(
    .INPUT_CLOCK(27000000),
    .BAUD_RATE(9600))
serial (
    .clk(clk),
    .rx(rx),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx_busy(tx_busy),
    .tx(tx));

endmodule