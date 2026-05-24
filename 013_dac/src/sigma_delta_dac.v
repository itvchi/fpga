module sigma_delta_dac (
    input clk,
    input rst_n,
    input load,
    input [9:0] value,
    output reg out
);

    reg [9:0] loaded_value_0;
    reg [9:0] loaded_value_1;
    reg loaded_value_ptr;
    reg [1:0] load_delay;
    reg [10:0] accumulator;
    reg [10:0] next_accumulator;

    always @(posedge clk) begin
        /* At load signal, set delay counter and store value in oposite register (currently unused) */
        if (load) begin
            if (loaded_value_ptr) begin
                loaded_value_0 <= value;
            end else begin
                loaded_value_1 <= value;
            end
            load_delay <= 2'd3;
        end

        /* If load_delay was set, then decrement, but before hits 0 and stop decrementing it flips active loaded_value_x register */
        if (load_delay) begin
            load_delay <= load_delay - 2'd1;
            if (load_delay == 2'd1) begin
                loaded_value_ptr = !loaded_value_ptr;
            end
        end
    end

    /* Calculate new accumulator value based on active loaded_value_x register */
    always @(*) begin
        if (out) begin
            if (loaded_value_ptr) begin
                next_accumulator = accumulator + loaded_value_1 - 11'd1023;
            end else begin
                next_accumulator = accumulator + loaded_value_0 - 11'd1023;
            end
        end else begin
            if (loaded_value_ptr) begin
                next_accumulator = accumulator + loaded_value_1;
            end else begin
                next_accumulator = accumulator + loaded_value_0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            accumulator <= 11'd0;
            out <= 1'b0;
        end else begin
            accumulator <= next_accumulator;
            out <= next_accumulator[10];
        end
    end

endmodule