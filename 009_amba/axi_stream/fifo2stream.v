module fifo2stream (
    input clk,
    input rst_n,
    input [31:0] data,
    input empty,
    output rd_en,
    input m_tready,
    output [7:0] m_tdata,
    output m_tvalid);

reg [31:0] r_data;
reg [7:0] tdata;
reg tvalid;
reg [2:0] byte_counter;
reg read_en;

/* State machine variables */
localparam 
STATE_IDLE = 2'd0,
STATE_READ_FIFO = 2'd1,
STATE_WRITE_STREAM = 2'd2;

reg [2:0] current_state;
reg [2:0] next_state;

/* Current state synchroniser */
always @(posedge clk) begin
    if (!rst_n) begin
        current_state <= STATE_IDLE;
    end else begin
        current_state <= next_state;
    end
end

/* Next state combinational logic */
always @(*) begin
    case (current_state)
        STATE_IDLE: begin
            if (!empty) begin
                next_state = STATE_READ_FIFO;
            end else begin
                next_state = current_state;
            end
        end
        STATE_READ_FIFO: begin
            next_state = STATE_WRITE_STREAM;
        end
        STATE_WRITE_STREAM: begin
            if (byte_counter == 2'b11 && m_tready) begin
                next_state = STATE_IDLE;
            end else begin
                next_state = current_state;
            end
        end
    endcase
end

/* */
always @(*) begin
    if (!rst_n) begin
        r_data = 32'd0;
        tdata = 8'd0;
        tvalid = 1'b0;
    end else begin
        tvalid = 1'b0;
        read_en = 1'b0;

        if (current_state == STATE_IDLE) begin
            tvalid = 1'b0;
        end
        if (current_state == STATE_IDLE && next_state == STATE_READ_FIFO) begin
            read_en = 1'b1;
        end
        if (current_state == STATE_READ_FIFO) begin
            r_data = data;
        end
        if (current_state == STATE_WRITE_STREAM) begin
            tdata = r_data[(byte_counter + 1)*8-1 -:8];
            tvalid = 1'b1;
        end
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        byte_counter <= 0;
    end else begin
        if (current_state == STATE_WRITE_STREAM) begin
            if (m_tready) begin
                byte_counter <= byte_counter + 1;
            end
        end else begin
            byte_counter <= 0;
        end
    end
end

assign rd_en = read_en;
assign m_tvalid = tvalid;
assign m_tdata = tdata;

endmodule