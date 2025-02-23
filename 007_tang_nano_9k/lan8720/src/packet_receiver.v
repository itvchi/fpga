/* This module is mainly based on module from https://github.com/HDLForBeginners/Toolbox/tree/main */

module packet_receiver #(
    parameter MII_WIDTH = 2,
    parameter [47:0]  FPGA_MAC = 48'he86a64e7e830,
    parameter CHECK_DESTINATION = 1
) (
    input clk,
    input rst_n,
    input [1:0] rxd,
    input rx_dv,
    output [31:0] data,
    output valid);

reg [MII_WIDTH*2-1:0] rxd_meta;
wire [MII_WIDTH-1:0] rxd_stable;
assign rxd_stable = rxd_meta[MII_WIDTH*2-1 -: MII_WIDTH];

reg [2:0] rxdv_meta;
wire rxdv_stable;
wire rxdv_stable_next;
assign rxdv_stable = rxdv_meta[2];
assign rxdv_stable_next = rxdv_meta[1];

always @(posedge clk) begin                                                                     
    if (!rst_n) begin                 
        rxd_meta <= 0;
        rxdv_meta <= 0;
    end else begin
        rxd_meta <= {rxd_meta[MII_WIDTH*2-1-MII_WIDTH:0], rxd};
        rxdv_meta <= {rxdv_meta[1:0], rx_dv};
    end
end

// write in received data until packet has ended
// this occurs when rxdv goes low.
wire packet_start;
assign packet_start = (rxdv_stable == 0 && rxdv_stable_next == 1);

wire packet_done;
assign packet_done = (rxdv_stable == 1 && rxdv_stable_next == 0);


/* Number of bytes transferred in each stage */
localparam
PREAMBLE_SFD_BYTES = 8,
_MAC_BYTES = 6,
_TYPE_BYTES = 2,
HEADER_BYTES = (2 * _MAC_BYTES + _TYPE_BYTES);

/* Packet length in *MII states */
localparam 
// PREAMBLE_SFD_LENGTH = PREAMBLE_BYTES*8/MII_WIDTH,
HEADER_LENGTH = HEADER_BYTES*8/MII_WIDTH;

// header and state buffers
reg [PREAMBLE_SFD_BYTES*8-1:0]  preamble_sfd_buffer;
wire [PREAMBLE_SFD_BYTES*8-1:0] preamble_sfd_buffer_next;
reg [7:0]       data_buffer;
reg [31:0]      output_buffer;
reg [HEADER_BYTES*8-1:0]  header_buffer;

/* State machine */
localparam
STATE_IDLE = 3'd0, 
STATE_PREAMBLE_SFD = 3'd1, 
STATE_HEADER = 3'd2, 
STATE_DATA = 3'd3;

reg [2:0]   current_state   = STATE_IDLE;
reg [2:0]   next_state      = STATE_IDLE;
reg [31:0]  state_counter;

always @(posedge clk) begin
    if (!rst_n) begin
        state_counter  <= 0;
    end else begin
        if (current_state != next_state) begin
            state_counter  <= 0;
        end else begin
            state_counter <= state_counter  + 32'd1;
        end
    end
end

// 3 process state machine
// 1) decide which state to go into next
always @(*) begin
    next_state = current_state;
    case (current_state)
        STATE_IDLE: begin
            if (packet_start) begin
                next_state = STATE_PREAMBLE_SFD;
            end
        end
        STATE_PREAMBLE_SFD: begin
            if (preamble_sfd_buffer_next == 64'hD555555555555555) begin
                next_state = STATE_HEADER;
            end
            // packet has ended, go back to IDLE
            if (packet_done) begin
                next_state = STATE_IDLE;
            end
        end
        STATE_HEADER: begin
            if (state_counter == HEADER_LENGTH-1) begin
                next_state = STATE_DATA;
            end
            // packet has ended, go back to IDLE
            if (packet_done) begin
                next_state = STATE_IDLE;
            end
        end
        STATE_DATA: begin
        // packet has ended, go back to IDLE
        if (packet_done) begin
            next_state = STATE_IDLE;
        end
    end
    default:
        next_state = current_state;
    endcase
end

//2) register into that state
always @(posedge clk) begin
    if (!rst_n) begin
        current_state <= STATE_IDLE;
    end else begin
        current_state <= next_state;
    end
end

reg data_valid;
reg [31:0] data_counter;

wire [47:0] dest_mac_little;
wire [47:0] dest_mac;
wire [47:0] src_mac_little;
wire [47:0] src_mac;
wire [15:0] length_little; 
wire [15:0] length;

assign dest_mac_little = header_buffer[47:0];
assign src_mac_little = header_buffer[95:48];
assign length_little = header_buffer[111:96];

assign dest_mac = {dest_mac_little[7:0], dest_mac_little[15:8], dest_mac_little[23:16], dest_mac_little[31:24], dest_mac_little[39:32], dest_mac_little[47:40]};
assign src_mac = {src_mac_little[7:0], src_mac_little[15:8], src_mac_little[23:16], src_mac_little[31:24], src_mac_little[39:32], src_mac_little[47:40]};
assign length = {length_little[7:0], length_little[15:8]};


assign preamble_sfd_buffer_next = rst_n ? {rxd_stable, preamble_sfd_buffer[PREAMBLE_SFD_BYTES*8-1:2]} : 64'd0;

// populate and shift buffers according to state
always@(posedge clk) begin
    if (!rst_n) begin
        preamble_sfd_buffer <= 0;
        header_buffer <= 0;
        data_buffer <= 0;
        data_valid <= 0;
        data_counter <= 0;
    end else begin
        /* Default assignments */
        data_valid <= 0;
        data_counter <= 0;
    
        // shift buffers during those states
        if (current_state == STATE_IDLE && next_state == STATE_PREAMBLE_SFD) begin
            preamble_sfd_buffer <= preamble_sfd_buffer_next;
        end
        if (current_state == STATE_PREAMBLE_SFD) begin
            preamble_sfd_buffer <= preamble_sfd_buffer_next;
        end
        if (current_state == STATE_HEADER) begin
            header_buffer <= {rxd_stable, header_buffer[HEADER_BYTES*8-1:2]};
        end
        if (current_state == STATE_DATA) begin
            data_counter <= data_counter;
            data_buffer <= {rxd_stable, data_buffer[7:2]};
            if ((state_counter[1:0]==3) && (~CHECK_DESTINATION || (src_mac == FPGA_MAC))) begin
                data_counter <= data_counter + 32'd1;
                if (data_counter < length) begin
                    output_buffer <= {data_buffer, output_buffer[31:8]};
                end
            end
            if (state_counter[1:0]==3 && data_counter == length) begin
                data_valid <= 1'b1;
            end
        end
    end
end

assign valid = data_valid;
assign data = output_buffer;

endmodule