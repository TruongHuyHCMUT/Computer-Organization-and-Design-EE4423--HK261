module dff (
    input logic clk, rst_n, en,
    input logic d,
    output logic q
);
    always_ff @(posedge clk or negedge rst_n) 
    begin
        if(!rst_n) begin   
            q <= 1'b0;
        end else if(en) begin 
            q <= d;
        end
    end
endmodule

module dff_2bit (
    input logic         clk, rst_n, en,
    input logic [1:0]   d,
    output logic [1:0]  q
);
    dff dff0 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[0]),
        .q      (q[0])
    );

    dff dff1 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[1]),
        .q      (q[1])
    );
endmodule

module dff_4bit (
    input logic         clk, rst_n, en,
    input logic [3:0]   d,
    output logic [3:0]  q   
);
    dff_2bit dff0 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[1:0]),
        .q      (q[1:0])
    );

    dff_2bit dff1 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[3:2]),
        .q      (q[3:2])
    );
endmodule

module dff_8bit (
    input logic         clk, rst_n, en,
    input logic [7:0]   d,
    output logic [7:0]  q
);
    dff_4bit dff0 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[3:0]),
        .q      (q[3:0])
    );

    dff_4bit dff1 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[7:4]),
        .q      (q[7:4])
    );
endmodule

module dff_16bit (
    input logic         clk, rst_n, en,
    input logic [15:0]  d,
    output logic [15:0] q
);
    dff_8bit dff0 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[7:0]),
        .q      (q[7:0])
    );

    dff_8bit dff1 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[15:8]),
        .q      (q[15:8])
    );
endmodule

module dff_32bit (
    input logic         clk, rst_n, en,
    input logic [31:0]  d,
    output logic [31:0] q
); 
    dff_16bit dff0 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[15:0]),
        .q      (q[15:0])
    );

    dff_16bit dff1 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .d      (d[31:16]),
        .q      (q[31:16])
    );
endmodule