module ws2812b (
    input i_clk,
    input i_send,
    input [7:0] i_red,
    input [7:0] i_green,
    input [7:0] i_blue,
    output o_data
);

localparam 
STATE_IDLE = 2'b00,
STATE_SEND = 2'b01,
STATE_END = 2'b10;

localparam 
T0H = 10,
T1H = 24,
T = 34;

reg [1:0] r_state;
reg [4:0] r_index;
reg [5:0] r_counter;
reg [23:0] r_color;
reg r_data;

initial
begin
    r_state <= 2'b00;
    r_index <= 5'd0;
    r_counter <= 6'd0;
    r_color <= 24'd0;
    r_data <= 1'b0;
end

always @(posedge i_clk) 
begin
    case(r_state)
        STATE_IDLE:
        begin
            if(i_send == 1'b1) r_state <= STATE_SEND;
            else r_state <= STATE_IDLE;
        end
        STATE_SEND:
        begin
            if (r_index < 24) r_state <= STATE_SEND;
            else r_state <= STATE_END;
        end
        STATE_END:
            r_state <= STATE_IDLE;
        default :
            r_state <= STATE_IDLE;
    endcase
end

always @ (posedge i_clk)
begin
    r_counter <= 6'd0;

    case(r_state)
        STATE_SEND:
            if(r_counter != T)
                r_counter <= r_counter + 6'd1;
    endcase
end

always @ (posedge i_clk)
begin
    r_index <= 5'd0;
    r_data <= 1'b0;

    case(r_state)
        STATE_IDLE:
            if(i_send == 1'b1) r_color <= {i_blue, i_green, i_red};

        STATE_SEND:
        begin
            r_index <= r_index;

            if(r_counter < (r_color[r_index] ? T1H : T0H))
                r_data <= 1'b1;
            else if(r_counter == T)
                r_index <= r_index + 5'd1;
        end
    endcase
end

assign o_data = r_data;

endmodule