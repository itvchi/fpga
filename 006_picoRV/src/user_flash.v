/* This module is only wrapper for gowin flash controller to access flash memory 
 * with PicoRV32 native bus - code performance test shown that is almost 4x slower than 
 * ececuting code from sram */

module user_flash (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [14:0] addr,
    input [31:0] data_i,
    output ready,
    output [31:0] data_o);

    localparam 
    STATE_IDLE = 2'b00,
    STATE_ACCESS = 2'b01,
    STATE_DONE = 2'b10;

    wire             wr_en;
    reg [1:0]        state = STATE_IDLE;
    reg              start_flag = 1'b0;
    wire             done_flag;
    wire             erase_en;

    assign wr_en = &wstrb; /* wr_en asserted only for word access to memory */
    assign erase_en = (wstrb == 4'b0001); /* erase_en asserted if byte write is written to a word alligned address */
    assign ready = (state == STATE_DONE);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_IDLE;
            start_flag = 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (select) begin
                        state <= STATE_ACCESS;
                        start_flag <= 1'b1;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end
                STATE_ACCESS: begin
                    start_flag <= 1'b0;
                    if (done_flag) begin
                        state <= STATE_DONE;
                    end else begin
                        state <= STATE_ACCESS;
                    end
                end
                STATE_DONE: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    Gowin_Flash_Controller_Top gw_flash_controller (
        .wdata_i(data_i),
        .wyaddr_i(addr[5:0]),  /* column address */ 
        .wxaddr_i(addr[14:6]), /* row addres */
        .erase_en_i(erase_en),
        .done_flag_o(done_flag),
        .start_flag_i(start_flag),
        .clk_i(clk),
        .nrst_i(reset_n),
        .rdata_o(data_o),
        .wr_en_i(wr_en));

endmodule