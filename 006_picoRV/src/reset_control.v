module reset_control (
    input clk,
    input rst_btn_n,
    output reset_n);

    reg [5:0] counter = 6'b0;

    assign reset_n = &counter; /* Assert reset_n when all counter is 6'b111111 */

    always @(posedge clk) begin
        if (rst_btn_n) begin
            counter <= counter + !reset_n; /* Increment counter when reset_n deasserted */
        end else begin
            counter <= 'b0; /* Reset counter on button press */
        end
    end

endmodule