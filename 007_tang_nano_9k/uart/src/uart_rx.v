module uart_rx (
    input clk,
    input clk_en,
    input rx,
    output reg [7:0] data,
    output data_valid);

localparam 
STATE_IDLE = 3'd0,
STATE_START_BIT = 3'd1,
STATE_READ = 3'd2,
STATE_WAIT = 3'd3,
STATE_STOP_BIT = 3'd4;

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
    if (clk_en) begin
        /* default assignments */
        data_bit <= 3'd0;

        case (state)
            STATE_IDLE: begin
                if (rx == 1'b0) begin/* wait for start bit */
                    state <= STATE_START_BIT;
                end else begin
                    state <= STATE_IDLE;
                end
            end
            STATE_START_BIT: begin /* state for 1 clock delay */
                state <= STATE_READ;
            end
            STATE_READ: begin /* shift data bit to register */
                fsm_data <= {rx, fsm_data[7:1]}; /* start append data at MSB, because first send bit is LSB and it will go to LSB at the end */
                data_bit <= data_bit + 3'd1;

                if(data_bit == 3'd7) begin /* end after 7th bit */
                    state <= STATE_STOP_BIT;
                end else begin
                    state <= STATE_WAIT;
                end
            end
            STATE_WAIT: begin /* wait 1 clock cycle */
                state <= STATE_READ;
            end
            STATE_STOP_BIT: begin
                data <= fsm_data;
                state <= STATE_IDLE;
            end
            default: 
                state <= STATE_IDLE;
        endcase
    end
end

assign data_valid = (state == STATE_STOP_BIT);

endmodule