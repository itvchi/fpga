module user_flash_custom #(parameter CLK_FREQ=27_000_000) (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [14:0]  addr, // word address, 9-bits row, 6 bits col
    input [31:0]  data_i,
    output ready,
    output [31:0] data_o
);

    /* state machine states */
    localparam 
    STATE_IDLE = 'd0,
    STATE_SELECT = 'd1,
    STATE_READ = 'd2,
    STATE_DONE = 'd3;

    /* flash memory constrol signals */
    reg xe = 1'b0;
    reg ye = 1'b0;
    reg se = 1'b0;
    reg [3:0] state = STATE_IDLE;

    assign ready = (state == STATE_DONE);

    always @(posedge clk or negedge reset_n) begin 
        if (!reset_n) begin
            se <= 1'b0;
            xe <= 1'b0;
            ye <= 1'b0;
            state <= STATE_IDLE;
        end else begin
            xe <= 1'b0;
            ye <= 1'b0;
            se <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    if (select) begin
                        if (wstrb == 'b0) begin /* Read operation */
                            xe <= 1'b1;
                            ye <= 1'b1;
                            state <= STATE_SELECT;
                        end else begin /* Other operations than read are unsupported now */
                            state <= STATE_DONE; /* Go through STATE_DONE to assert ready signal */
                        end
                    end else
                        state <= STATE_IDLE;
                    end
                STATE_SELECT: begin /* Asert memory select signal - at least 5ns (max CLK_FREQ=200MHz) */
                    xe <= 1'b1;
                    ye <= 1'b1;
                    se <= 1'b1;
                    state <= STATE_READ;
                end
                STATE_READ: begin /* Deassert select signal - memory data are valid now */
                    xe <= 1'b1;
                    ye <= 1'b1;
                    se <= 1'b0;
                    state <= STATE_DONE;
                end
                STATE_DONE: begin /* Deassert other signals and go to STATE_IDLE */
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    Gowin_User_Flash gw_flash (
        .dout(data_o), //output [31:0] dout
        .xe(xe), //input xe
        .ye(ye), //input ye
        .se(se), //input se
        .prog('b0), //input prog
        .erase('b0), //input erase
        .nvstr('b0), //input nvstr
        .xadr(addr[14:6]), //input [8:0] xadr
        .yadr(addr[5:0]), //input [5:0] yadr
        .din(data_i) //input [31:0] din
    );

endmodule