module decoder3to8(
    input logic A0, A1, A2, En,
    output  logic D0, D1, D2, D3, D4, D5, D6, D7
);  
    assign D0 = ~A0 & ~A1 & ~A2 & En;
    assign D1 =  A0 & ~A1 & ~A2 & En;
    assign D2 = ~A0 &  A1 & ~A2 & En;
    assign D3 =  A0 &  A1 & ~A2 & En;
    assign D4 = ~A0 & ~A1 &  A2 & En;
    assign D5 =  A0 & ~A1 &  A2 & En;
    assign D6 = ~A0 &  A1 &  A2 & En;
    assign D7 =  A0 &  A1 &  A2 & En;   
endmodule   


module decoder2to4 (
    input logic A0, A1, En,
    output logic D0, D1, D2, D3
);
    assign D0 = ~A1 & ~A0 & En;
    assign D1 = ~A1 & A0 & En;
    assign D2 = A1 & ~A0 & En;
    assign D3 = A1 & A0 & En;    
endmodule 

module decoder (
    input logic A0, A1, A2, A3, A4,
    input logic En,
    output logic [31:0] D
);
    logic [3:0] Decode_sel;
    decoder2to4 dec_sel(
        .A0(A3), .A1(A4), .En(En),
        .D0(Decode_sel[0]), .D1(Decode_sel[1]), .D2(Decode_sel[2]), .D3(Decode_sel[3])
    );
    decoder3to8 dec0(
        .A0(A0), .A1(A1), .A2(A2), .En(Decode_sel[0]),
        .D0(D[0]), .D1(D[1]), .D2(D[2]), .D3(D[3]), .D4(D[4]), .D5(D[5]), .D6(D[6]), .D7(D[7])
    );
    decoder3to8 dec1(
        .A0(A0), .A1(A1), .A2(A2), .En(Decode_sel[1]),
        .D0(D[8]), .D1(D[9]), .D2(D[10]), .D3(D[11]), .D4(D[12]), .D5(D[13]), .D6(D[14]), .D7(D[15])
    );
    decoder3to8 dec2(
        .A0(A0), .A1(A1), .A2(A2), .En(Decode_sel[2]),
        .D0(D[16]), .D1(D[17]), .D2(D[18]), .D3(D[19]), .D4(D[20]), .D5(D[21]), .D6(D[22]), .D7(D[23])
    );
    decoder3to8 dec3(
        .A0(A0), .A1(A1), .A2(A2), .En(Decode_sel[3]),
        .D0(D[24]), .D1(D[25]), .D2(D[26]), .D3(D[27]), .D4(D[28]), .D5(D[29]), .D6(D[30]), .D7(D[31])
    );
endmodule