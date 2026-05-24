module sine_lut (
    input clk,
    input clk_en,
    input  wire [8:0] addr,
    output reg  [9:0] value,
    output reg data_ready
);

    wire [1:0] quarter = addr[8:7];
    wire [6:0] index = addr[6:0];

    reg [6:0] offset;
    reg [9:0] lut_data;

    reg offset_valid;
    reg lut_data_valid;

    // quarter mapping
    always @(posedge clk) begin
        offset_valid <= 1'b0;

        if (clk_en) begin
            offset_valid <= 1'b1;

            case (quarter)
                2'b00: offset <= index;          // 0..π/2
                2'b01: offset <= 7'd127 - index; // π/2..π
                2'b10: offset <= index;          // π..3π/2
                2'b11: offset <= 7'd127 - index; // 3π/2..2π
            endcase
        end
    end

    // quarter sine LUT (0..π/2)
    always @(posedge clk) begin
        lut_data_valid <= 1'b0;

        if (offset_valid) begin
            lut_data_valid <= 1'b1;

            case (offset)
                7'd0: lut_data = 10'd0;
                7'd1: lut_data = 10'd6;
                7'd2: lut_data = 10'd13;
                7'd3: lut_data = 10'd19;
                7'd4: lut_data = 10'd25;
                7'd5: lut_data = 10'd32;
                7'd6: lut_data = 10'd38;
                7'd7: lut_data = 10'd44;
                7'd8: lut_data = 10'd50;
                7'd9: lut_data = 10'd57;
                7'd10: lut_data = 10'd63;
                7'd11: lut_data = 10'd69;
                7'd12: lut_data = 10'd76;
                7'd13: lut_data = 10'd82;
                7'd14: lut_data = 10'd88;
                7'd15: lut_data = 10'd94;
                7'd16: lut_data = 10'd100;
                7'd17: lut_data = 10'd107;
                7'd18: lut_data = 10'd113;
                7'd19: lut_data = 10'd119;
                7'd20: lut_data = 10'd125;
                7'd21: lut_data = 10'd131;
                7'd22: lut_data = 10'd137;
                7'd23: lut_data = 10'd143;
                7'd24: lut_data = 10'd149;
                7'd25: lut_data = 10'd156;
                7'd26: lut_data = 10'd162;
                7'd27: lut_data = 10'd167;
                7'd28: lut_data = 10'd173;
                7'd29: lut_data = 10'd179;
                7'd30: lut_data = 10'd185;
                7'd31: lut_data = 10'd191;
                7'd32: lut_data = 10'd197;
                7'd33: lut_data = 10'd203;
                7'd34: lut_data = 10'd209;
                7'd35: lut_data = 10'd214;
                7'd36: lut_data = 10'd220;
                7'd37: lut_data = 10'd226;
                7'd38: lut_data = 10'd231;
                7'd39: lut_data = 10'd237;
                7'd40: lut_data = 10'd243;
                7'd41: lut_data = 10'd248;
                7'd42: lut_data = 10'd254;
                7'd43: lut_data = 10'd259;
                7'd44: lut_data = 10'd265;
                7'd45: lut_data = 10'd270;
                7'd46: lut_data = 10'd275;
                7'd47: lut_data = 10'd281;
                7'd48: lut_data = 10'd286;
                7'd49: lut_data = 10'd291;
                7'd50: lut_data = 10'd296;
                7'd51: lut_data = 10'd301;
                7'd52: lut_data = 10'd306;
                7'd53: lut_data = 10'd311;
                7'd54: lut_data = 10'd316;
                7'd55: lut_data = 10'd321;
                7'd56: lut_data = 10'd326;
                7'd57: lut_data = 10'd331;
                7'd58: lut_data = 10'd336;
                7'd59: lut_data = 10'd341;
                7'd60: lut_data = 10'd345;
                7'd61: lut_data = 10'd350;
                7'd62: lut_data = 10'd355;
                7'd63: lut_data = 10'd359;
                7'd64: lut_data = 10'd364;
                7'd65: lut_data = 10'd368;
                7'd66: lut_data = 10'd372;
                7'd67: lut_data = 10'd377;
                7'd68: lut_data = 10'd381;
                7'd69: lut_data = 10'd385;
                7'd70: lut_data = 10'd389;
                7'd71: lut_data = 10'd393;
                7'd72: lut_data = 10'd397;
                7'd73: lut_data = 10'd401;
                7'd74: lut_data = 10'd405;
                7'd75: lut_data = 10'd409;
                7'd76: lut_data = 10'd413;
                7'd77: lut_data = 10'd416;
                7'd78: lut_data = 10'd420;
                7'd79: lut_data = 10'd424;
                7'd80: lut_data = 10'd427;
                7'd81: lut_data = 10'd431;
                7'd82: lut_data = 10'd434;
                7'd83: lut_data = 10'd437;
                7'd84: lut_data = 10'd440;
                7'd85: lut_data = 10'd444;
                7'd86: lut_data = 10'd447;
                7'd87: lut_data = 10'd450;
                7'd88: lut_data = 10'd453;
                7'd89: lut_data = 10'd456;
                7'd90: lut_data = 10'd458;
                7'd91: lut_data = 10'd461;
                7'd92: lut_data = 10'd464;
                7'd93: lut_data = 10'd466;
                7'd94: lut_data = 10'd469;
                7'd95: lut_data = 10'd471;
                7'd96: lut_data = 10'd474;
                7'd97: lut_data = 10'd476;
                7'd98: lut_data = 10'd478;
                7'd99: lut_data = 10'd481;
                7'd100: lut_data = 10'd483;
                7'd101: lut_data = 10'd485;
                7'd102: lut_data = 10'd487;
                7'd103: lut_data = 10'd489;
                7'd104: lut_data = 10'd490;
                7'd105: lut_data = 10'd492;
                7'd106: lut_data = 10'd494;
                7'd107: lut_data = 10'd495;
                7'd108: lut_data = 10'd497;
                7'd109: lut_data = 10'd498;
                7'd110: lut_data = 10'd500;
                7'd111: lut_data = 10'd501;
                7'd112: lut_data = 10'd502;
                7'd113: lut_data = 10'd503;
                7'd114: lut_data = 10'd504;
                7'd115: lut_data = 10'd505;
                7'd116: lut_data = 10'd506;
                7'd117: lut_data = 10'd507;
                7'd118: lut_data = 10'd508;
                7'd119: lut_data = 10'd509;
                7'd120: lut_data = 10'd509;
                7'd121: lut_data = 10'd510;
                7'd122: lut_data = 10'd510;
                7'd123: lut_data = 10'd510;
                7'd124: lut_data = 10'd511;
                7'd125: lut_data = 10'd511;
                7'd126: lut_data = 10'd511;
                7'd127: lut_data = 10'd511;
            endcase
        end
    end

    // sign + offset mapping
    always @(posedge clk) begin
        data_ready <= 1'b0;

        if (lut_data_valid) begin
            data_ready <= 1'b1;

            case (quarter)
                2'b00: value <= 10'd512 + lut_data;
                2'b01: value <= 10'd512 + lut_data;
                2'b10: value <= 10'd512 - lut_data;
                2'b11: value <= 10'd512 - lut_data;
            endcase
        end
    end

endmodule