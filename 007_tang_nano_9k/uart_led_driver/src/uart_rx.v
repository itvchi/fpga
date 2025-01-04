module uart_rx (
    input clk,
    input clk_en,
    input rx,
    output reg [7:0] data,
    output reg data_valid);

localparam 
STATE_IDLE = 3'd0,
STATE_START_BIT = 3'd1,
STATE_READ = 3'd2,
STATE_WAIT = 3'd3,
STATE_STOP_BIT = 3'd4,
STATE_STOP_BIT_WAIT = 3'd5;

reg [3:0] state;
reg [2:0] data_bit;
reg [7:0] fsm_data;

initial begin
    state <= STATE_IDLE;
    data_bit <= 2'd0;
    fsm_data <= 8'd0;
end

/* UART receiver state machine */
always @(posedge clk) begin
    /* default assignments */
    data_valid <= 1'b0;

    case (state)
        STATE_IDLE: begin
            if (rx == 1'b0 && clk_en) begin/* wait for start bit */
                data_bit <= 3'd0;
                state <= STATE_START_BIT;
            end else begin
                state <= STATE_IDLE;
            end
        end
        STATE_START_BIT: begin /* state for 1 clock delay */
            if (clk_en) begin
                state <= STATE_READ;
            end else begin
                state <= STATE_START_BIT;
            end
        end
        STATE_READ: begin /* shift data bit to register */
            if (clk_en) begin
                fsm_data <= {rx, fsm_data[7:1]}; /* start append data at MSB, because first send bit is LSB and it will go to LSB at the end */
                data_bit <= data_bit + 3'd1;

                if(data_bit == 3'd7) begin /* end after 7th bit */
                    state <= STATE_STOP_BIT;
                end else begin
                    state <= STATE_WAIT;
                end 
            end else begin
                state <= STATE_READ;
            end
        end
        STATE_WAIT: begin /* wait 1 clock cycle */
            if (clk_en) begin
                state <= STATE_READ;
            end else begin
                state <= STATE_WAIT;
            end
        end
        STATE_STOP_BIT: begin
            data <= fsm_data;
            data_valid <= 1'b1;
            state <= STATE_STOP_BIT_WAIT;
        end
        STATE_STOP_BIT_WAIT: begin /* wait for second clk_en signal for stop bit */
            if (clk_en) begin
                state <= STATE_IDLE;
            end else begin
                state <= STATE_STOP_BIT_WAIT;
            end
        end
        default: 
            state <= STATE_IDLE;
    endcase
end

endmodule