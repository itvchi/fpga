
`timescale 1ns / 100ps

module spi_master_tb();

reg clk;
reg rst_n;
reg [7:0] data;
reg valid;
wire ready;
wire spi_clk;
wire spi_mosi;
wire spi_cs;

spi_master UUT (
    .clk(clk),
    .rst_n(rst_n),
    .data(data),
    .valid(valid),
    .ready(ready),
    .spi_cs(spi_cs),
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi));


/* Generate clock signal */
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

/* Generate reset signal */
initial begin
    rst_n <= 1'b0;
    #20
    rst_n = 1'b1;
end

initial begin
    $dumpfile("spi_master_tb.vcd");
    $dumpvars(0, spi_master_tb);
end

// Wait until SPI Master is ready
task wait_ready;
    begin
        @(posedge clk);  // Wait for rising edge first
        while (!ready) begin
            @(posedge clk);  // Only check `ready` on clock edges
        end
    end
endtask

task send_byte(input [7:0] byte);
    begin
        wait_ready();    // Wait until SPI master is ready
        data <= byte;  // Assign data after ready is seen
        valid <= 1'b1; // Assert valid
        @(posedge clk); // Hold for at least one full cycle
        valid <= 1'b0; // Deassert valid after one cycle
        @(posedge clk); // Hold for at least one full cycle
        while (!spi_cs) begin
            @(posedge clk);  // Only check `spi_cs` on clock edges
        end
    end
endtask

// Send Continuous Data Without Deasserting `valid`
task send_data(input [7:0] byte);
    begin
        wait_ready();  // Ensure ready before sending
        @(posedge clk);
        valid = 1;
        data = byte;
    end
endtask

// End Multi-Byte Transaction (Deassert `valid`)
task send_last(input [7:0] byte);
    begin
        wait_ready();  // Ensure ready before sending
        @(posedge clk);
        valid = 1;
        data = byte;
        wait_ready();
        @(posedge clk);      // Hold valid for at least one cycle
        valid <= 1'b0;       // Deassert valid
        wait_ready();
    end
endtask

// Test Scenario
initial begin
    valid = 0;
    data = 8'h00;
    #100;  // Wait for reset

    send_byte(8'hA5);  // Single-byte transmission
    #500;

    send_data(8'h55);  // Start burst
    send_data(8'h33);
    send_last(8'h0F);  // End burst

    #200;
    $finish;
end

endmodule