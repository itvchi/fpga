module spiflash_reader (
    input clk,
    input reset_n,
    input [23:0] addr, /* 24-bit api memory address */
    input [4:0] burst_size, /* up to 64 byte (need 5 bit wide input); for value 0, read 1 byte, so we can ommit one bit */
    input start,
    output reg [7:0] data_o,
    output reg data_valid,
    output reg [5:0] burst_idx, /* index of output byte in burst */
    output busy);

    reg [3:0] state;
    reg [3:0] next_state;
    reg [23:0] spi_data_o;
    reg [9:0] spi_data_bits;
    reg [7:0] spi_data_i;

    reg flash_cs;
    reg flash_clk;
    reg flash_mosi;
    wire flash_miso;

    wire flash_io0;
    wire flash_io1;
    wire flash_io2;
    wire flash_io3;

    assign flash_io0 = flash_mosi;
    assign flash_miso = flash_io1;
    assign flash_io2 = 1'bz;
    assign flash_io3 = 1'bz;

    spiflash memory (
        .csb(flash_cs),
        .clk(flash_clk),
        .io0(flash_io0),
        .io1(flash_io1),
        .io2(flash_io2),
        .io3(flash_io3));

    localparam
    STATE_IDLE = 4'd0,
    STATE_RESET = 4'd1,
    STATE_RESET_DONE = 4'd2,
    STATE_POWER_UP = 4'd3,
    STATE_POWER_UP_DONE = 4'd4,
    STATE_SEND_COMMAND = 4'd5,
    STATE_SEND_ADDRESS = 4'd6,
    STATE_SEND_PRELOAD = 4'd7,
    STATE_SEND = 4'd8,
    STATE_READ_DATA = 4'd9,
    STATE_READ = 4'd10;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            /* Initialize reset procedure */
            state <= STATE_IDLE;
            next_state <= STATE_RESET;
            /* Initialize internal flash signals */
            flash_cs <= 1'b1;
            flash_clk <= 1'b0;
            flash_mosi <= 1'b0;
            /* Initialize module output signals */
            data_o <= 8'd0;
            data_valid <= 1'b0;
        end else begin
            /* Default assignaments */
            data_valid <= 1'b0;
            flash_cs <= 1'b1;

            case (state)
                STATE_IDLE: begin
                    flash_clk <= 1'b0;
                    state <= next_state;
                    
                    if (start) begin
                        next_state <= STATE_SEND_COMMAND;
                    end
                end
                STATE_RESET: begin
                    flash_cs <= 1'b0;
                    flash_clk <= 1'b0;
                    spi_data_bits <= 8;
                    spi_data_o[23-:8] <= 8'hff;
                    state <= STATE_SEND_PRELOAD;
                    next_state <= STATE_RESET_DONE;
                end
                STATE_RESET_DONE: begin
                    flash_cs <= 1'b1;
                    flash_clk <= 1'b0;
                    state <= STATE_POWER_UP;
                end
                STATE_POWER_UP: begin
                    flash_cs <= 1'b0;
                    flash_clk <= 1'b0;
                    spi_data_bits <= 8;
                    spi_data_o[23-:8] <= 8'hAB;
                    state <= STATE_SEND_PRELOAD;
                    next_state <= STATE_POWER_UP_DONE;
                end
                STATE_POWER_UP_DONE: begin
                    flash_cs <= 1'b1;
                    flash_clk <= 1'b0;
                    state <= STATE_IDLE;
                    next_state <= STATE_IDLE;
                end
                STATE_SEND_COMMAND: begin
                    flash_cs <= 1'b0;
                    spi_data_bits <= 8;
                    spi_data_o[23-:8] <= 8'h03;
                    state <= STATE_SEND_PRELOAD;
                    next_state <= STATE_SEND_ADDRESS;
                end
                STATE_SEND_ADDRESS: begin
                    flash_cs <= 1'b0;
                    spi_data_bits <= 24;
                    spi_data_o <= addr;
                    state <= STATE_SEND_PRELOAD;
                    next_state <= STATE_READ_DATA;
                end
                STATE_SEND_PRELOAD: begin
                    state <= STATE_SEND;
                    flash_cs <= 1'b0;
                    flash_mosi <= spi_data_o[23];
                end
                STATE_SEND: begin
                    state <= STATE_SEND;
                    flash_cs <= 1'b0;

                    if (flash_clk) begin
                        flash_clk <= 1'b0;
                        if(spi_data_bits == 0) begin
                            flash_mosi <= 1'b0;
                            state <= next_state;
                        end
                    end else begin
                        flash_clk <= 1'b1;
                        flash_mosi <= spi_data_o[23];
                        spi_data_o <= {spi_data_o[22:0], 1'b0};
                        spi_data_bits <= spi_data_bits - 1;
                    end
                end
                STATE_READ_DATA: begin
                    flash_cs <= 1'b0;
                    state <= STATE_READ;
                    spi_data_bits <= 8; /* Read one byt from passed address */
                end
                STATE_READ: begin
                    flash_cs <= 1'b0;
                    state <= STATE_READ;

                    if (flash_clk) begin
                        flash_clk <= 1'b0;

                        if (spi_data_bits[2:0] == 0) begin
                            data_o <= spi_data_i;
                            data_valid <= 1'b1;
                        end

                        if (spi_data_bits == 0) begin
                            state <= STATE_IDLE;
                            next_state <= STATE_IDLE;
                        end
                    end else begin
                        flash_clk <= 1'b1;
                        spi_data_i <= {spi_data_i[6:0], flash_miso};
                        spi_data_bits <= spi_data_bits - 1;
                    end
                end
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    assign busy = (state != STATE_IDLE);

endmodule