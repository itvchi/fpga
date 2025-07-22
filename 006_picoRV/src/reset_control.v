module reset_control (
    input clk,
    input rst_btn_n,
    output reset_n);

    reg [1:0] rst_btn_n_stable;
    reg [17:0] counter;

    assign reset_n = &counter; /* Assert reset_n when all counter is 10'b111111 */

    always @(posedge clk) begin
        rst_btn_n_stable <= {rst_btn_n_stable[0], rst_btn_n};

        if (!rst_btn_n_stable[1]) begin
            counter <= 18'd0; /* Reset counter on button press */
        end else begin
            if (!reset_n) begin /* Increment counter when reset_n deasserted */
                counter <= counter + 18'd1; 
            end
        end
    end

endmodule