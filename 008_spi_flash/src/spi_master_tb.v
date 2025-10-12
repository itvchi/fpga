`timescale 1ns / 100ps

module spi_master_tb();

    // Control signals
    reg clk;
    reg rst_n;
    reg cpol;
    reg cpha;

    // Module interface
    reg [7:0] tx_data;
    reg tx_valid;
    wire tx_ready;
    wire [7:0] rx_data;
    wire rx_valid;
    wire busy;

    // SPI interface
    wire spi_clk;
    wire spi_mosi;
    reg spi_miso;
    wire spi_cs;

    // Instantiate DUT
    spi_master UUT (
        .clk(clk),
        .rst_n(rst_n),
        .prescaler(8'd1), /* Increase prescaler, because miso driver have lag (this change not influence tested module behaviour, 
            but allows to change testbench signals in more suitable moment - without it we have one clock cycle lag for miso signal, and another lag inside UUT, 
            which filters metastability on spi_miso pin - another lag which enforced minimal hardware prescaler value, but this can be done at this side and 
            will not influence module behaviour, so it will work the same if mosi signal will change at edge change, not one clk after it as in testbench) */
        .cpol(cpol),
        .cpha(cpha),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .busy(busy),
        .spi_cs(spi_cs),
        .spi_clk(spi_clk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso));

    //---------------------------------------
    // Clock and reset generation
    //---------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    initial begin
        rst_n = 0;
        #40;
        rst_n = 1;
    end

    //---------------------------------------
    // Waveform dump, initialize test counters
    //---------------------------------------
    integer test_count, error_count;
    initial begin
        $dumpfile("spi_master_tb.vcd");
        $dumpvars(0, spi_master_tb);
        test_count = 0;
        error_count = 0;
    end

    //---------------------------------------
    // Timeout-protected waiters
    //---------------------------------------
    task wait_ready;
        integer timeout;
        begin
            timeout = 0;
            while (!tx_ready && timeout < 1000000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 1000000)
                $fatal(1, "Timeout waiting for ready!");
        end
    endtask

    task wait_not_busy;
        integer timeout;
        begin
            timeout = 0;
            while (busy && timeout < 1000000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 1000000)
                $fatal(1, "Timeout waiting for not busy!");
        end
    endtask

    task wait_rx_valid;
        integer timeout;
        begin
            timeout = 0;
            while (!rx_valid && timeout < 1000000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 1000000)
                $fatal(1, "Timeout waiting for rx_valid!");
        end
    endtask

    task send_byte_nowait(input [7:0] byte);
        begin
            @(posedge clk);
            tx_data  <= byte;
            tx_valid <= 1'b1;
            wait_ready();
            @(posedge clk);
            tx_valid <= 1'b0;
        end
    endtask

    task send_byte(input [7:0] byte);
        begin
            send_byte_nowait(byte);
            @(posedge clk);
            wait_not_busy();
        end
    endtask

    task test_send_byte(input polarity, input phase, input [7:0] byte);
        begin
            test_count = test_count + 1;

            cpol <= polarity;
            cpha <= phase;
            #200;
            send_byte(byte);

            if (spi_data === byte) begin
                $display("\tSend byte 0x%02h - OK", byte);
            end else begin
                error_count = error_count + 1;
                $display("\tSend byte 0x%02h - FAIL (expected 0x%02h)", spi_data, byte);
            end
        end
    endtask

    task test_send_bytes(input [7:0] byte0, input [7:0] byte1, input [7:0] byte2, input [7:0] byte3);
        reg [7:0] bytes [3:0];
        begin
            test_count = test_count + 1;

            send_byte_nowait(byte0);
            send_byte_nowait(byte1);
            bytes[0] = spi_data;
            send_byte_nowait(byte2);
            bytes[1] = spi_data;
            send_byte_nowait(byte3);
            bytes[2] = spi_data;
            @(posedge clk);
            wait_not_busy();
            bytes[3] = spi_data;
            
            if (byte0 === bytes[0] && byte1 === bytes[1] && byte2 === bytes[2] && byte3 === bytes[3]) begin
                $display("\tSend bytes 0x%02h 0x%02h 0x%02h 0x%02h - OK", byte0, byte1, byte2, byte3);
            end else begin
                error_count = error_count + 1;
                $display("\tSend bytes 0x%02h 0x%02h 0x%02h 0x%02h - FAIL (expected 0x%02h 0x%02h 0x%02h 0x%02h)", bytes[0], bytes[1], bytes[2], bytes[3], byte0, byte1, byte2, byte3);
            end
        end
    endtask

    task test_receive_byte(input polarity, input phase, input [7:0] byte);
        reg [7:0] rx_byte;
        begin
            test_count = test_count + 1;

            cpol <= polarity;
            cpha <= phase;
            spi_miso_data <= byte; /* Configure data which will be put on MISO */
            #200;
            send_byte_nowait(8'h00);
            @(posedge clk);
            wait_rx_valid();
            rx_byte = rx_data; // blocking (this is ok - or use non-blocking but wait for clock cycle to register)
            wait_not_busy();

            if (rx_byte === byte) begin
                $display("\tReceived byte 0x%02h - OK", byte);
            end else begin
                error_count = error_count + 1;
                $display("\tReceived byte 0x%02h - FAIL (expected 0x%02h)", rx_byte, byte);
            end
        end
    endtask

    //---------------------------------------
    // SPI MOSI monitor - probes mosi signal to compare if it is same as tx_data
    // SPI MISO driver - puts miso signal on the bus to compare with rx_data
    //---------------------------------------
    reg spi_cs_prev;
    reg spi_clk_prev;
    reg spi_mosi_prev;
    reg [7:0] spi_mosi_data;
    reg [7:0] spi_miso_data;
    reg [7:0] spi_data;
    reg [2:0] spi_bitcount;

    initial begin
        spi_miso_data = 1'b0;
    end

    always @(posedge clk) begin
        /* Register previous signals for edge detection and common probe time */
        spi_cs_prev <= spi_cs;
        spi_clk_prev <= spi_clk;
        spi_mosi_prev <= spi_mosi;

        /* SPI chip select is ative */
        if ({spi_cs_prev, spi_cs} == 2'b10) begin
            spi_mosi_data <= 8'd0;
            spi_bitcount <= 3'd0;
            spi_miso <= spi_miso_data[7];
            /* For cpha == 1'b1, the change should omit first change edge, otherwise we can shift here */
            if (cpha == 1'b0) begin
                spi_miso_data <= {spi_miso_data[6:0], spi_miso_data[7]};
            end
        end
        /* SPI chip select is inactive */
        if ({spi_cs_prev, spi_cs} == 2'b01) begin
            spi_data <= spi_mosi_data;
            spi_miso <= 1'b0;
        end

        if ({spi_cs_prev, spi_cs} == 2'b00) begin
            if (cpol == cpha) begin 
                /* Probe mosi at rising edge */
                if ({spi_clk_prev, spi_clk} == 2'b01) begin
                    spi_bitcount <= spi_bitcount + 3'd1;
                    spi_mosi_data <= {spi_mosi_data[6:0], spi_mosi_prev};
                end
                /* Change miso at falling edge */
                if ({spi_clk_prev, spi_clk} == 2'b10) begin
                    spi_miso_data <= {spi_miso_data[6:0], spi_miso_data[7]};
                    spi_miso <= spi_miso_data[7];
                end
            end else begin 
                /* Probe mosi at falling edge */
                if ({spi_clk_prev, spi_clk} == 2'b10) begin
                    spi_bitcount <= spi_bitcount + 3'd1;
                    spi_mosi_data <= {spi_mosi_data[6:0], spi_mosi_prev};
                end   
                /* Change miso at rising edge */
                if ({spi_clk_prev, spi_clk} == 2'b01) begin
                    spi_miso_data <= {spi_miso_data[6:0], spi_miso_data[7]};
                    spi_miso <= spi_miso_data[7];
                end          
            end
        end

        /* Latch mosi registered data from shift register at first spi_clk_edge when spi_bitcount wraps */
        if ({spi_clk_prev, spi_clk} == 2'b01 || {spi_clk_prev, spi_clk} == 2'b10) begin
            if (spi_bitcount == 3'd0) begin
                spi_data <= spi_mosi_data;
            end
        end
    end

    //---------------------------------------
    // Test sequences
    //---------------------------------------
    initial begin
        cpol = 0;
        cpha = 0;
        tx_valid = 0;
        tx_data  = 8'h00;
        spi_miso = 0;
        #100; // wait for reset release

        // ---------- TX single byte test ----------
        $display("=== TX single byte test ===");
        test_send_byte(1'b0, 1'b0, 8'hA5);
        test_send_byte(1'b1, 1'b0, 8'hA5);
        test_send_byte(1'b0, 1'b1, 8'hA5);
        test_send_byte(1'b1, 1'b1, 8'hA5);
        #100;
        cpol = 0;
        cpha = 0;
        #100;

        // ---------- TX multi byte test ----------
        $display("=== TX multi byte test ===");
        test_send_bytes(8'h22, 8'hC3, 8'h44, 8'hD2);
        #100

        // ---------- RX single byte test ----------
        $display("=== RX single byte test ===");
        test_receive_byte(1'b0, 1'b0, 8'hA5);
        test_receive_byte(1'b1, 1'b0, 8'hA5);
        test_receive_byte(1'b0, 1'b1, 8'hA5);
        test_receive_byte(1'b1, 1'b1, 8'hA5);
        #100;
        cpol = 0;
        cpha = 0;
        #100;

        // ---------- Summarize test results ----------
        if (error_count) begin
            $display("TEST FAILED - (%0d/%0d OK)", test_count - error_count, test_count);
        end else begin
            $display("TEST PASSED - (%0d/%0d OK)", test_count, test_count);
        end
        #200;
        $finish;
    end

endmodule