module color_generator (
    input i_clk,
    output o_send,
    output [7:0] o_red,
    output [7:0] o_green,
    output [7:0] o_blue
);

reg [23:0] r_counter;
reg [23:0] r_data;
reg r_send;

initial
begin
    r_counter <= 24'd0;
    r_data <= {8'h00, 8'h00, 8'hFF};
    r_send <= 1'b0;
end

always @ (posedge i_clk)
begin
    r_counter <= r_counter + 24'd1;
end

always @ (posedge i_clk)
begin
    r_data <= r_data;
    r_send <= 1'b0;

    if(r_counter == 24'd0)
    begin  
        r_data <= {r_data[15:0], r_data[23:16]};
        r_send <= 1'b1;
    end
end

assign o_red = r_data[7:0];
assign o_green = r_data[15:8];
assign o_blue = r_data[23:16];
assign o_send = r_send;

endmodule