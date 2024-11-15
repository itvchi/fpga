module pwm #( parameter CHANNELS=1) (
  input clk,
  input n_rst,
  input [7:0] pwm_value [CHANNELS-1:0],
  output reg [CHANNELS-1:0] pwm_out);

reg [15:0] r_counter;
reg [7:0] r_pwm_value [CHANNELS-1:0];

integer index;

always @(posedge clk) begin
    if (n_rst == 1'b0) begin
        for (index=0; index<CHANNELS; index=index+1) begin
            r_pwm_value[index] <= 8'd0;
        end
    end else begin
        if (r_counter == 16'd0) begin
            for (index=0; index<CHANNELS; index=index+1) begin
                r_pwm_value[index] <= pwm_value[index];
            end
            
        end
    end
end

always @(posedge clk) begin
    if (n_rst == 1'b0) begin
        r_counter <= 16'd0;
    end else begin
        r_counter <= r_counter + 16'd1;
    end
end

genvar inst;
generate
    for (inst=0; inst<CHANNELS; inst=inst+1) begin
        assign pwm_out[inst] = (r_counter[15 -: 8] < r_pwm_value[inst]);
    end
endgenerate

endmodule