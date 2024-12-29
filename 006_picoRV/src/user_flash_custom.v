module user_flash_custom #(parameter CLK_FREQ=27_000_000) (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [14:0]  addr, // word address, 9-bits row, 6 bits col
    input [31:0]  data_i,
    output ready,
    output reg [31:0] data_o
);

    reg [14:0] flash_addr;
    wire [31:0] flash_data_o;

    /* GW1NR-9 flash is 304 rows x 64 columns x 32 (4B) = 608Kb (76KB)
     * Cache of size 64B will fit 4 columns of word size, \
     * so we have 304 rows x 4 columns x 64B (16 words) */
    /* flash memory cache - 2D array (8 entries x 16 words) */
    localparam 
    C_ENTRIES = 8,
    C_WORDS = 16;
    reg [31:0] cache_line [(C_ENTRIES-1):0][(C_WORDS-1):0];
    /* Address mapping to cache:
     * 1:0   (2b)  - word select of memory address (not passed on address bus of memory interface)
     * 7:2   (6b)  - column address
     * 16:8  (9b)  - row address
     * 31:17 (15b) - address upper part, not used here because it is related with select signal on the bus
     */
    /* From above, address of ach word in memory is addressed with 15bits (9b of row address and 6b of col address)
     * When we use 64B sized cache, we store 16 words (16 columns) in cache line - so 4 lower bits of column address 
     * selects now column inside cache line and 2 upper bits goes to next address part.
     * We have 8 entries no-way associative cache, so next 3 bits from address are used to select cache line.
     * So we have 4bits for column select in cache line, 3bits for cache line entry select and we 8bits (15-4-3) for TAG purpose 
     * Entry contain full cache line of 64B (16 columnx x 32bits), so we have to tag each entry to know what memory address is inside cache line */

    /* Cache TAG that contains upper address part of memory, which unambiguously connects address range with cache line 
     * Higest bit is also used to mark cache_line as valid - we have no information at startup if TAG of value 0 contains 
     * loaded cache lines, it just relates cache_line with the TAG part of address 
     * CACHE_TAG = address[14:7], ENTRY = address[6:4], CACHE_LINE_COLUMN = address[3:0] */
    reg [8:0] cache_tag [(C_ENTRIES-1):0];

    /* Invalidate cache tags */
    initial begin
        for (integer i = 0; i < C_ENTRIES; i = i + 1) begin
            cache_tag[i] = 'd0; 
        end
    end

    /* state machine states */
    localparam 
    STATE_IDLE = 'd0,
    STATE_LOAD = 'd1,
    STATE_SELECT = 'd2,
    STATE_READ = 'd3,
    STATE_STORE = 'd4,
    STATE_DONE = 'd5;

    /* flash memory constrol signals */
    reg xe = 1'b0;
    reg ye = 1'b0;
    reg se = 1'b0;
    reg [3:0] state = STATE_IDLE;
    reg [4:0] column;

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
                            if (cache_tag[addr[6:4]] == {1'b1, addr[14:7]}) begin /* cache_line valid */
                                data_o <= cache_line[addr[6:4]][addr[3:0]]; /* load data from cache_line */
                                state <= STATE_DONE; /* Go through STATE_DONE to assert ready signal */
                            end else begin
                                xe <= 1'b1;
                                ye <= 1'b1;
                                column <= 5'd0;
                                state <= STATE_LOAD;
                            end
                        end else begin /* Other operations than read are unsupported now */
                            state <= STATE_DONE; /* Go through STATE_DONE to assert ready signal */
                        end
                    end else
                        state <= STATE_IDLE;
                    end
                STATE_LOAD: begin
                    flash_addr <= {addr[14:7], addr[6:4], column[3:0]}; /* Set flash address to cache_line beginning */
                    xe <= 1'b1;
                    ye <= 1'b1;
                    if (column == 5'b10000) begin /* Last read complete - update tag and return requested data */
                        cache_tag[addr[6:4]] = {1'b1, addr[14:7]}; 
                        data_o <= cache_line[addr[6:4]][addr[3:0]];
                        state <= STATE_DONE;
                    end else begin
                        state <= STATE_SELECT;
                    end
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
                    state <= STATE_STORE;
                end
                STATE_STORE: begin /* Store memory data into cache_line and go next column */
                    xe <= 1'b0;
                    ye <= 1'b0;
                    cache_line[addr[6:4]][column] <= flash_data_o; /* Update data in cache line */
                    column <= column + 'b1;
                    state <= STATE_LOAD;
                end
                STATE_DONE: begin /* Go to STATE_IDLE, ready signal is asserted in this state */
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    Gowin_User_Flash gw_flash (
        .dout(flash_data_o), //output [31:0] dout
        .xe(xe), //input xe
        .ye(ye), //input ye
        .se(se), //input se
        .prog('b0), //input prog
        .erase('b0), //input erase
        .nvstr('b0), //input nvstr
        .xadr(flash_addr[14:6]), //input [8:0] xadr
        .yadr(flash_addr[5:0]), //input [5:0] yadr
        .din(data_i) //input [31:0] din
    );

endmodule