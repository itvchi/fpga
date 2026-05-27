module top (
    input clk_ref,
    input rst_n,
    input clk_meas
);

    /* RESET SIGNAL SYNCHRONIZATION */
    reg [2:0] ref_rst_n_sync;
    reg [2:0] meas_rst_n_sync;
    wire ref_rst_n = ref_rst_n_sync[2];
    wire meas_rst_n = meas_rst_n_sync[2];
    
    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin
            ref_rst_n_sync <= 3'd0;
        end else begin
            ref_rst_n_sync <= {ref_rst_n_sync[1:0], 1'b1};
        end
    end

    always @(posedge clk_meas or negedge rst_n) begin
        if (!rst_n) begin
            meas_rst_n_sync <= 3'd0;
        end else begin
            meas_rst_n_sync <= {meas_rst_n_sync[1:0], 1'b1};
        end
    end

    /* GATE ENABLE GENERATION */
    reg gate_en;
    reg [31:0] gate_counter;

    localparam [31:0] GATE_COUNTER_INIT = 32'd100_000 - 1; //1ms

    always @(posedge clk_ref) begin
        if (!ref_rst_n) begin
            gate_en <= 1'b0;
            gate_counter <= GATE_COUNTER_INIT;
        end else begin
            if (meas_sm_idle_stable == 2'b01) begin
                gate_en <= 1'b1;
                gate_counter <= GATE_COUNTER_INIT;
            end else if (gate_en) begin
                if (gate_counter == 0) begin
                    gate_en <= 1'b0;
                end else begin
                    gate_counter <= gate_counter - 32'd1;
                end
            end
        end
    end

    /* MEAS_SM STATES CDC (MEASURED CLOCK DOMAIN -> REFERENCE CLOCK DOMAIN) */
    reg [1:0] meas_sm_idle_stable;
    reg [1:0] meas_sm_work_stable;

    always @(posedge clk_ref) begin
        if (!ref_rst_n) begin
            meas_sm_idle_stable <= 2'd0;
            meas_sm_work_stable <= 2'd0;
        end else begin
            meas_sm_idle_stable <= {meas_sm_idle_stable[0], meas_sm_idle};
            meas_sm_work_stable <= {meas_sm_work_stable[0], meas_sm_work};
        end
    end

    /* GATE ENABLE CDC (REFERENCE CLOCK DOMAIN -> MEASURED CLOCK DOMAIN) */
    reg gate_en_meta;
    reg gate_en_sync;
    reg gate_en_prev;

    always @(posedge clk_meas) begin
        if (!meas_rst_n) begin
            gate_en_meta <= 1'b0;
            gate_en_sync <= 1'b0;
            gate_en_prev <= 1'b0;
        end else begin
            gate_en_meta <= gate_en;
            gate_en_sync <= gate_en_meta;
            gate_en_prev <= gate_en_sync;
        end
    end

    wire gate_rising  = (gate_en_sync & ~gate_en_prev);
    wire gate_falling = (~gate_en_sync & gate_en_prev);

    /* MEASURED CLOCK DOMAIN STATE MACHINE */
    reg [1:0] meas_sm;
    reg [1:0] next_meas_sm;
    reg meas_sm_idle;
    reg meas_sm_work;

    localparam
    MEAS_SM_IDLE = 2'b00,
    MEAS_SM_WORK = 2'b01,
    MEAS_SM_DONE = 2'b11,
    MEAS_SM_SAVE = 2'b10;

    always @(posedge clk_meas) begin
        if (!meas_rst_n) begin
            meas_sm <= MEAS_SM_IDLE;
            meas_sm_idle <= 1'b1;
            meas_sm_work <= 1'b0;
        end else begin
            meas_sm <= next_meas_sm;
            meas_sm_idle <= (next_meas_sm == MEAS_SM_IDLE);
            meas_sm_work <= (next_meas_sm == MEAS_SM_WORK);
        end
    end

    always @(*) begin
        case (meas_sm)
            MEAS_SM_IDLE: begin
                if (gate_rising) begin
                    next_meas_sm = MEAS_SM_WORK;
                end else begin
                    next_meas_sm = MEAS_SM_IDLE;
                end
            end
            MEAS_SM_WORK: begin
                if (gate_falling) begin
                    next_meas_sm = MEAS_SM_DONE;
                end else begin
                    next_meas_sm = MEAS_SM_WORK;
                end
            end
            MEAS_SM_DONE: begin
                next_meas_sm = MEAS_SM_SAVE;
            end
            MEAS_SM_SAVE: begin
                next_meas_sm = MEAS_SM_IDLE;
            end
            default: begin
                next_meas_sm = MEAS_SM_IDLE;
            end
        endcase
    end

    /* MEASURED CLOCK DOMAIN MEASUREMENT COUNTER */
    reg [63:0] meas_counter;

    always @(posedge clk_meas) begin
        if (!meas_rst_n) begin
            meas_counter <= 0;
        end else begin
            if (meas_sm == MEAS_SM_IDLE) begin
                meas_counter <= 0;
            end else if (meas_sm == MEAS_SM_WORK) begin
                meas_counter <= meas_counter + 64'd1;
            end
        end
    end

    /* REFERENCE CLOCK DOMAIN MEASUREMENT COUNTER */
    reg [63:0] ref_counter;

    always @(posedge clk_ref) begin
        if (!ref_rst_n) begin
            ref_counter <= 0;
        end else begin
            if (meas_sm_idle_stable == 2'b01) begin
                ref_counter <= 0; //reset on enter into IDLE
            end else if (meas_sm_work_stable[1]) begin
                ref_counter <= ref_counter + 64'd1; //count during WORK
            end
        end
    end

endmodule