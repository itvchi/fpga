module uart (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [4:0] addr, /* 32 byte address space - up to 8 registers of word size */
    input [31:0] data_i,
    output reg ready,
    output reg [31:0] data_o,
    input rx,
    output tx,
    output reg irq_rx,
    output reg irq_tx);

reg [31:0]      r_config;       /* offset: 0x00  RW */
reg [31:0]      r_baud_presc;   /* offset: 0x04  RW */
reg [31:0]      r_status;       /* offset: 0x08  RW */
reg [7:0]       r_rx_data;      /* offset: 0x0C  R  */
reg [7:0]       r_tx_data;      /* offset: 0x10  W  */

wire            config_reset = r_config[0];
wire            config_enable = r_config[1];
wire            config_rx_irq = r_config[2];
wire            config_tx_irq = r_config[3];
wire            status_rx_valid = r_status[0];
wire            status_tx_done = r_status[1];

/* baud_generator, uart_rx and uart_tx signals */
reg baud_enable;
wire clk_en; /* not used yet */
wire [7:0] uart_rx_data;
reg [7:0] uart_tx_data;
wire data_valid;
reg new_tx_data;
reg start;
wire busy;
wire tx_done;

initial begin
    r_config <= 32'd0;
    r_baud_presc <= 32'd0;
    r_status <= 32'd0;
    r_rx_data <= 8'd0;
    r_tx_data <= 8'd0;
    baud_enable <= 1'b0;
    irq_rx <= 1'b0;
    irq_tx <= 1'b0;
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        r_config <= 32'd0;
        r_baud_presc <= 32'd0;
        r_status <= 32'd0;
        r_rx_data <= 8'd0;
        r_tx_data <= 8'd0;
        irq_rx <= 1'b0;
        irq_tx <= 1'b0;
        ready <= 1'b0;
    end else begin
        ready <= 1'b0;
        r_config <= r_config;
        r_status <= r_status;

        if (select) begin
            if (wstrb == 'd0) begin
                case (addr)
                    8'h00:  data_o <= r_config;
                    8'h04:  data_o <= r_baud_presc;
                    8'h08:  data_o <= r_status;
                    8'h0C:  data_o <= {24'd0, r_rx_data};
                    8'h10:  data_o <= 32'd0;
                endcase
            end else begin
                case (addr)
                    8'h00:  r_config <= data_i;
                    8'h04:  r_baud_presc <= data_i;
                    8'h08:  r_status <= data_i;
                    8'h10:  begin
                        r_tx_data <= data_i[7:0];
                        new_tx_data <= 1'b1;
                    end
                endcase
            end
            ready <= 1'b1;
        end
        
        if (config_reset) begin
            r_config <= 32'd0;
            r_baud_presc <= 32'd0;
            r_status <= 32'd0;
            r_rx_data <= 32'd0;
            r_tx_data <= 32'd0;
            irq_rx <= 1'b0;
            irq_tx <= 1'b0;
        end else if (config_enable) begin
            /* Enable baud_generator, when r_baud_presc is != 0 */
            if (r_baud_presc) begin
                baud_enable <= 1'b1;
            end else begin
                baud_enable <= 1'b0;
            end

            /* Set rx data ready bit in r_status register - set by hardware, reset by software */
            if (data_valid) begin 
                r_rx_data <= uart_rx_data;
                r_status[0] <= 1'b1;
            end

            /* Set tx busy bit in r_status register - set and reset by hardware */
            if (busy) begin
                r_status[1] <= 1'b1;
            end else begin
                r_status[1] <= 1'b0;
            end

            /* Handle start pulse on data write to tx register */
            if (new_tx_data) begin
                uart_tx_data <= r_tx_data;
                start <= 1'b1;
                new_tx_data <= 1'b0;
            end else begin
                start <= 1'b0;
            end

            /* Pass tx_done signal outside as interrupt if enabled */
            if (config_tx_irq) begin
                irq_tx <= tx_done;
            end else begin
                irq_tx <= 1'b0;
            end
        end
    end
end


reg clk_counter;

initial begin
    clk_counter <= 1'b0;
end

wire clk_en_half;
assign clk_en_half = clk_en && clk_counter;

always @(posedge clk) begin
    if (clk_en) begin 
        clk_counter <= clk_counter + 1'b1;
    end else begin
        clk_counter <= clk_counter;
    end
end

baud_generator bg (
    .clk(clk),
    .reset_n(reset_n),
    .enable(baud_enable),
    .ticks(r_baud_presc),
    .clk_en(clk_en));

/* RX part uses clk_en of 2*BAUD_RATE to sample incomming data in the middle */
uart_rx serial_rx (
    .clk(clk),
    .clk_en(clk_en),
    .rx(rx),
    .data(uart_rx_data),
    .data_valid(data_valid));

uart_tx serial_tx (
    .clk(clk),
    .clk_en(clk_en_half),
    .start(start),
    .data(uart_tx_data),
    .tx(tx),
    .busy(busy),
    .tx_done(tx_done));

endmodule







module baud_generator (
    input clk,
    input reset_n,
    input enable,
    input [31:0] ticks,
    output reg clk_en);

    reg [31:0] counter;

    initial begin
        counter <= 'd0;
        clk_en <= 'd0;
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 'd0;
            clk_en <= 'd0;
        end else if (enable) begin
            if (counter == (ticks - 1)) begin
                counter <= 'd0;
                clk_en <= 1'b1;
            end else begin
                counter <= counter + 'd1;
                clk_en <= 0;
            end
        end
    end

endmodule


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


module uart_tx (
    input clk,
    input clk_en,
    input start,
    input [7:0] data,
    output reg tx,
    output busy,
    output reg tx_done);

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
        tx <= 1'b1;
        tx_done <= 1'b0;
    end

    //Transmitter block
    always @(posedge clk) begin
        tx_done <= 1'b0;

        case (state)
            STATE_IDLE: begin
                if(start == 1'b1) begin
                    data_bit <= 1'b0;
                    fsm_data <= data;
                    state <= STATE_START_BIT;
                end else begin
                    state <= STATE_IDLE;
                end
            end
            STATE_START_BIT: begin
                if (clk_en) begin
                    tx <= 1'b0;
                    state <= STATE_DATA_BIT;
                end else begin
                    state <= STATE_START_BIT;
                end
            end
            STATE_DATA_BIT: begin
                state <= STATE_DATA_BIT;

                if (clk_en) begin
                    tx <= fsm_data[data_bit];
                    data_bit <= data_bit + 3'd1;

                    if(data_bit == 3'd7) begin
                        state <= STATE_STOP_BIT;
                    end
                end
            end
            STATE_STOP_BIT: begin
                if (clk_en) begin
                    tx <= 1'b1;
                    tx_done <= 1'b1;
                    state <= STATE_IDLE;
                end else begin
                    state <= STATE_STOP_BIT;
                end
            end
            default:
                state <= STATE_IDLE;
        endcase
    end

    assign busy = (state != STATE_IDLE);

endmodule