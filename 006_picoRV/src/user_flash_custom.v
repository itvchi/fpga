module user_flash_custom #(parameter CLK_FREQ=27_000_000) (
    input clk,
    input reset_n,
    input select,
    input [3:0] wstrb,
    input [14:0]  addr, // word address, 9-bits row, 6 bits col
    input [31:0]  data_i,
    output ready,
    output reg [31:0] data_o,
    output reg cache_hit,
    output reg cache_miss
);

    reg [14:0] flash_addr;
    wire [31:0] flash_data_o;

    /* GW1NR-9 flash is 304 rows x 64 columns x 32 (4B) = 608Kb (76KB)
     * Cache of size 64B will fit 4 columns of word size, \
     * so we have 304 rows x 4 columns x 64B (16 words) */
    /* flash memory cache - 2D array (2 ways x 4 sets x 16 words) */
    localparam 
    C_WAY = 2,
    C_SETS = 4,
    C_WORDS = 16;
    reg [31:0] cache_line [((C_WAY*C_SETS)-1):0][(C_WORDS-1):0];
    /* Address mapping to cache:
     * 1:0   (2b)  - word select of memory address (not passed on address bus of memory interface)
     * 7:2   (6b)  - column address
     * 16:8  (9b)  - row address
     * 31:17 (15b) - address upper part, not used here because it is related with select signal on the bus
     */
    /* From above, address of ach word in memory is addressed with 15bits (9b of row address and 6b of col address)
     * When we use 64B sized cache, we store 16 words (16 columns) in cache line - so 4 lower bits of column address 
     * selects now column inside cache line and 2 upper bits goes to next address part.
     * We have 8 set no-way associative cache, so next 3 bits from address are used to select cache line.
     * So we have 4bits for column select in cache line, 2bits for cache line set select and we 9bits (15-4-2) for TAG purpose 
     * Set contain full cache line of 64B (16 columnx x 32bits), so we have to tag each set to know what memory address is inside cache line */

    /* Cache TAG that contains upper address part of memory, which unambiguously connects address range with cache line 
     * Two higest bit is also used to mark cache_line as valid - we have no information at startup if TAG of value 0 contains 
     * loaded cache lines, it just relates cache_line with the TAG part of address and recent_used bit that is set for last used cache line 
     * in the set (other cache lines in the set are zeroed then and this cache_lines are preffered to change when cache miss for this set occurs)
     * CACHE_TAG = address[14:6], CACHE_SET = address[5:4], CACHE_LINE_COLUMN = address[3:0] */
    reg [10:0] cache_tag [((C_WAY*C_SETS)-1):0];
    
    localparam
    LAST_USED_BIT = 10,
    VALID_BIT = 9;

    /* Invalidate cache tags */
    integer i;
    initial begin
        for (i = 0; i < (C_WAY*C_SETS); i = i + 1) begin
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
    reg cache_set;

    assign ready = (state == STATE_DONE);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cache_hit <= 1'b0;
            cache_miss <= 1'b0;
            se <= 1'b0;
            xe <= 1'b0;
            ye <= 1'b0;
            state <= STATE_IDLE;
        end else begin
            cache_hit <= 1'b0;
            cache_miss <= 1'b0;
            xe <= 1'b0;
            ye <= 1'b0;
            se <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    if (select) begin
                        if (wstrb == 'b0) begin /* Read operation */
                            if (cache_tag[{1'b0, addr[5:4]}][9:0] == {1'b1, addr[14:6]}) begin /* cache_line valid */
                                cache_tag[{1'b0, addr[5:4]}][LAST_USED_BIT] <= 1'b1; /* mark this cache_line in set as last used */
                                cache_tag[{1'b1, addr[5:4]}][LAST_USED_BIT] <= 1'b0; /* and unmark this, what will cause override on next cache miss for this set */
                                data_o <= cache_line[{1'b0, addr[5:4]}][addr[3:0]]; /* load data from cache_line */
                                state <= STATE_DONE; /* Go through STATE_DONE to assert ready signal */
                                cache_hit <= 1'b1;
                            end else if (cache_tag[{1'b1, addr[5:4]}][9:0] == {1'b1, addr[14:6]}) begin
                                cache_tag[{1'b1, addr[5:4]}][LAST_USED_BIT] <= 1'b0;
                                cache_tag[{1'b0, addr[5:4]}][LAST_USED_BIT] <= 1'b1;
                                data_o <= cache_line[{1'b1, addr[5:4]}][addr[3:0]];
                                state <= STATE_DONE;
                                cache_hit <= 1'b1;
                            end else begin
                                xe <= 1'b1;
                                ye <= 1'b1;
                                column <= 5'd0;
                                if (cache_tag[{1'b0, addr[5:4]}][LAST_USED_BIT]) begin /* Select active set for operation */                                    
                                    cache_set <= 1'b1; /* If set 0 is last used override set 1 */
                                end else begin
                                    cache_set <= 1'b0; /* Oposite from above */
                                end
                                state <= STATE_LOAD;
                                cache_miss <= 1'b1;
                            end
                        end else begin /* Other operations than read are unsupported now */
                            state <= STATE_DONE; /* Go through STATE_DONE to assert ready signal */
                        end
                    end else
                        state <= STATE_IDLE;
                    end
                STATE_LOAD: begin
                    flash_addr <= {addr[14:4], column[3:0]}; /* Set flash address to cache_line beginning */
                    xe <= 1'b1;
                    ye <= 1'b1;
                    if (column == 5'b10000) begin /* Last read complete - update tag and return requested data */
                        cache_tag[{cache_set, addr[5:4]}] = {1'b1, 1'b1, addr[14:6]}; /* also mark last valid bit */
                        data_o <= cache_line[{cache_set, addr[5:4]}][addr[3:0]];
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
                    cache_line[{cache_set, addr[5:4]}][column] <= flash_data_o; /* Update data in cache line */
                    column <= column + 5'b1;
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