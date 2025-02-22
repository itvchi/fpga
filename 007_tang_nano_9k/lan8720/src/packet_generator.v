/* This module is mainly based on module from https://github.com/HDLForBeginners/Examples/tree/main/eth_counter */

module packet_generator #(
    parameter MII_WIDTH = 2,
    parameter DEST_MAC = 48'hffffffffffff,
    parameter SRC_MAC = 48'he86a64e7e830
) (
    input clk,
    input rst_n,
    input start,
    input [31:0] data,
    output [MII_WIDTH-1:0] tx,
    output tx_en);

/* Number of bytes transferred in each stage */
localparam
PREAMBLE_BYTES = 7,
SFD_BYTES = 1,
_MAC_BYTES = 6,
_TYPE_BYTES = 2,
HEADER_BYTES = (2 * _MAC_BYTES + _TYPE_BYTES),
DATA_BYTES = 46, /* payload up to 46 bytes + padding for minimum packet length of 64 bytes */
FCS_BYTES = 4,
WAIT_BYTES = 12;

/* Packet length in *MII states */
localparam 
PREAMBLE_LENGTH = PREAMBLE_BYTES*8/MII_WIDTH,
SFD_LENGTH = SFD_BYTES*8/MII_WIDTH,
HEADER_LENGTH = HEADER_BYTES*8/MII_WIDTH,
DATA_LENGTH = DATA_BYTES*8/MII_WIDTH,
FCS_LENGTH = FCS_BYTES*8/MII_WIDTH,
WAIT_LENGTH = WAIT_BYTES*8/MII_WIDTH;

/* Buffers */
reg [PREAMBLE_BYTES*8-1:0]  preamble_buffer;
reg [SFD_BYTES*8-1:0]       sfd_buffer;
reg [HEADER_BYTES*8-1:0]    header_buffer;
wire [15:0]                 data_payload_bytes;
reg [7:0]                   data_buffer;
wire [FCS_BYTES*8-1:0]      fcs;
reg [FCS_BYTES*8-1:0]       fcs_buffer;

/* State machine */
localparam
STATE_IDLE = 3'd0, 
STATE_PREAMBLE = 3'd1, 
STATE_SFD = 3'd2, 
STATE_HEADER = 3'd3, 
STATE_DATA = 3'd4, 
STATE_FCS = 3'd5, 
STATE_WAIT = 3'd6;

reg [2:0]   current_state   = STATE_IDLE;
reg [2:0]   next_state      = STATE_IDLE;
reg [31:0]  state_counter;

/* Count cycles in each state */
always @(negedge clk) begin
    if(!rst_n) begin
        state_counter <= 32'd0;
    end else begin
        if (current_state != next_state) begin
            state_counter <= 32'd0;
        end else begin
            state_counter <= state_counter  + 32'd1;
        end
    end
end

/* Calculate next state */
always @(*) begin
    case (current_state)
        STATE_IDLE: begin
            if (start) begin
                next_state = STATE_PREAMBLE;
            end else begin
                next_state = current_state;
            end
        end
        STATE_PREAMBLE: begin
            if (state_counter == PREAMBLE_LENGTH-1) begin
                next_state = STATE_SFD;
            end else begin
                next_state = current_state;
            end
        end
        STATE_SFD: begin
            if (state_counter == SFD_LENGTH-1) begin
                next_state = STATE_HEADER;
            end else begin
                next_state = current_state;
            end
        end
        STATE_HEADER: begin
            if (state_counter == HEADER_LENGTH-1) begin
                next_state = STATE_DATA;
            end else begin
                next_state = current_state;
            end
        end
        STATE_DATA: begin
            if (state_counter == DATA_LENGTH-1) begin
                next_state = STATE_FCS;
            end else begin
                next_state = current_state;
            end
        end
        STATE_FCS:
        begin
            if (state_counter == FCS_LENGTH-1) begin
                next_state = STATE_WAIT;
            end else begin
                next_state = current_state;
            end
        end
        STATE_WAIT:
        begin
            if (state_counter == WAIT_LENGTH-1) begin
                next_state = STATE_IDLE;
            end else begin
                next_state = current_state;
            end
        end
        default:
            next_state = current_state;
    endcase
end

/* Set current state from calculated next_state  */
always @(negedge clk)
    begin
    if (!rst_n) begin
        current_state <= STATE_IDLE;
    end else begin
        current_state <= next_state;
    end
end

/* state dependant variables */
reg [MII_WIDTH-1:0] tx_data;
reg tx_valid;
reg fcs_en;
reg fcs_rst;

always @(*) begin
    case (current_state)
        STATE_IDLE: begin
            tx_valid = 1'b0;
            tx_data = 1'b0;
            fcs_en = 1'b0;
            fcs_rst = 1'b1;
        end
        STATE_PREAMBLE: begin
            tx_valid = 1'b1;
            tx_data = preamble_buffer[MII_WIDTH-1:0];
            fcs_en = 1'b0;
            fcs_rst = 1'b0;
        end
        STATE_SFD: begin
            tx_valid = 1'b1;
            tx_data = sfd_buffer[MII_WIDTH-1:0];
            fcs_en = 1'b0;
            fcs_rst = 1'b0;
        end
        STATE_HEADER: begin
            tx_valid = 1'b1;
            tx_data = header_buffer[MII_WIDTH-1:0];
            fcs_en = 1'b1;
            fcs_rst = 1'b0;
        end
        STATE_DATA: begin
            tx_valid = 1'b1;
            tx_data = data_buffer[MII_WIDTH-1:0];
            fcs_en = 1'b1;
            fcs_rst = 1'b0;
        end
        STATE_FCS: begin
            tx_valid = 1'b1;
            tx_data = fcs_buffer[MII_WIDTH-1:0];
            fcs_en = 1'b0;
            fcs_rst = 1'b0;
        end
        STATE_WAIT: begin
            tx_valid = 1'b0;
            tx_data = 1'b0;
            fcs_en = 1'b0;
            fcs_rst = 1'b0;
        end
        default: begin
            tx_valid = 1'b0;
            tx_data = 1'b0;
            fcs_en = 1'b0;
            fcs_rst = 1'b0;
        end
    endcase
end

/* populate and shift buffers according to state */
always @(negedge clk) begin
    if (!rst_n) begin
        header_buffer <= 0;
        preamble_buffer <= 0;
        data_buffer <= 0;
    end else begin

        /* preload buffers */
        if (current_state == STATE_IDLE) begin
            preamble_buffer <= 56'h55555555555555;
            sfd_buffer <= 8'hD5;
            header_buffer <= {8'd4, 8'd0, /* Payload size is 4 bytes of input data register */
                            SRC_MAC[7:0], SRC_MAC[15:8], SRC_MAC[23:16], SRC_MAC[31:24], SRC_MAC[39:32], SRC_MAC[47:40],
                            DEST_MAC[7:0], DEST_MAC[15:8], DEST_MAC[23:16], DEST_MAC[31:24], DEST_MAC[39:32], DEST_MAC[47:40]};
        end
        if (next_state == STATE_DATA && current_state != STATE_DATA) begin
            data_buffer <= data[7:0];
        end
        if (next_state == STATE_FCS && current_state != STATE_FCS) begin
            fcs_buffer <= fcs;
        end

        /* shift buffers during states */
        if (current_state == STATE_PREAMBLE) begin
            preamble_buffer <= preamble_buffer >> MII_WIDTH;
        end
        if (current_state == STATE_SFD) begin
            sfd_buffer <= sfd_buffer >> MII_WIDTH;
        end
        if (next_state == STATE_FCS && current_state != STATE_FCS) begin
            sfd_buffer <= sfd_buffer >> MII_WIDTH;
        end
        if (current_state == STATE_HEADER) begin
            header_buffer <= header_buffer >> MII_WIDTH;
        end
        if (current_state == STATE_DATA && next_state == STATE_DATA) begin
            if (state_counter[1:0] == 3) begin
                /* Load next data byte (data buffer or padding zeros) at last MII cycle */
                if (state_counter[31:2] < 4) begin
                    data_buffer <= data[((state_counter[31:2] + 1)*8 + 7) -:8];
                end else begin
                    data_buffer <= 8'h00;
                end
            end else begin
                data_buffer <= data_buffer >> MII_WIDTH;
            end
        end
        if (current_state == STATE_FCS) begin
            fcs_buffer <= fcs_buffer >> MII_WIDTH;
        end
    end
end

crc_gen fsc_crc(
    .clk(clk),
    .rst(!rst_n || fcs_rst),
    .data_in(tx_data),
    .crc_en(fcs_en),
    .crc_out(fcs));

/* Assign local regs to module output interface */
assign tx_en = tx_valid;
assign tx = tx_data;

endmodule