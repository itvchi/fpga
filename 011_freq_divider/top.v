module acc_counter(
    input clk,
    input [31:0] acc_value,
    output reg carry);

reg [31:0] counter = 0;

always @(posedge clk) begin
    {carry, counter} <= counter + acc_value;
end

endmodule

module freq_divider(
    input clk,
    input carry,
    output freq);

reg [31:0] sec_counter = 0;
reg [31:0] pulse_counter = 0;

always @(posedge clk) begin
    if (sec_counter == 100000) begin
        sec_counter <= 32'd0;
    end else begin
        sec_counter <= sec_counter + 32'd1;
    end
end

always @(posedge clk) begin
    if (sec_counter == 100000) begin
        pulse_counter <= 32'd0;
    end else if (carry) begin
        pulse_counter <= pulse_counter + 32'd1;
    end 
end

endmodule

module top(
    input clk,
    output freq);

wire carry;

acc_counter acc(
    .clk(clk),
    .acc_value(4300000),
    .carry(carry));

freq_divider fd(
    .clk(clk),
    .carry(carry),
    .freq(freq));

endmodule