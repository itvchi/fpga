module uart_tx (
    input clk,
    input clk_en,
    input start,
    input [7:0] data,
    output reg tx,
    output busy);

localparam 
STATE_IDLE = 3'd0,
STATE_START_BIT = 3'd1,
STATE_DATA_BIT = 3'd2,
STATE_STOP_BIT = 3'd3,
STATE_WAIT = 3'd4;

reg [3:0] state;
reg [2:0] data_bit;
reg [7:0] fsm_data;

initial begin
    state <= STATE_IDLE;
    data_bit <= 3'd0;
    fsm_data <= 8'd0;
end



//Transmitter block
always @(posedge clk) begin
    if (clk_en) begin
        /* default assignments */
        data_bit <= 1'b0;

        case (state)
            STATE_IDLE: begin
                if(start == 1'b1) begin
                    tx <= 1'b0;
                    fsm_data <= data;
                    state <= STATE_START_BIT;
                end else begin
                    state <= STATE_IDLE;
                end
            end
            STATE_START_BIT: begin
                tx <= fsm_data[data_bit];
                data_bit <= data_bit + 3'd1;
                state <= STATE_DATA_BIT;
            end
            STATE_DATA_BIT: begin
                tx <= fsm_data[data_bit];
                data_bit <= data_bit + 3'd1;

                if(data_bit == 3'd7) begin
                    state <= STATE_STOP_BIT;
                end else begin
                    state <= STATE_DATA_BIT;
                end
            end
            STATE_STOP_BIT: begin
                tx <= 1'b1;
                state <= STATE_IDLE;
            end
            default:
                state <= STATE_IDLE;
        endcase
    end
end

assign busy = (state != STATE_IDLE);

endmodule