module mm_leds ( /* Memmory mapped leds */
    input clk,
    input reset_n,
    input select,
    input [31:0] data_i,
    input write_en,
    output ready,
    output [31:0] data_o);

    reg [5:0] leds = 'b0;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            leds <= 'b0;
        end else if(select) begin
            if (write_en) begin
                leds <= data_i[5:0];
            end
        end
    end

    assign data_o = {26'd0, leds};
    assign ready = select;

endmodule