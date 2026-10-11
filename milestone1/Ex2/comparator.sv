module comparator (
    input logic [31:0]  i_a, i_b,
    input logic         i_unsigned,
    output logic        o_eq, o_lt, o_gt
);
    logic           w_lt, w_lt_signed, w_slt;
    logic   [31:0]  slt_sum;
    logic           w_sltu;
    logic           w_sgt, w_sgtu;

    FA #(.WIDTH(32)) slt_fa (
        .a      (i_a),
        .b      (~i_b),
        .cin    (1'b1),
        .sum    (slt_sum),
        .cout   (w_lt)
    );

// Set less than (signed) 
    assign w_lt_signed = i_a[31] ^ i_b[31];
    assign w_slt = w_lt_signed ? i_a[31] : slt_sum[31];

// Set less than (unsigned) 
    assign w_sltu = ~w_lt;

// Equal (signed and unsigned)
    assign o_eq = ~(|(i_a ^ i_b));

// Set greater than (signed)
    assign w_sgt = ~(o_eq | w_slt);
// Set greater than (unsigned)
    assign w_sgtu = ~(o_eq | w_sltu);

    assign o_lt = i_unsigned ? w_sltu : w_slt;
    assign o_gt = ~(o_eq | o_lt);
endmodule

module fa (
    input logic     a, b, cin,
    output logic    sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule 

module FA #(
    parameter int WIDTH = 32
) (
    input logic [WIDTH-1:0]     a, b,
    input logic                 cin,
    output logic [WIDTH-1:0]    sum,
    output logic                cout
);
    logic [WIDTH:0]   w_carry;
    assign w_carry[0] = cin;
    genvar i;
    generate 
        for (i = 0; i < WIDTH; i++ ) begin : gen_fa
            fa dut_fa (
                .a      (a[i]),
                .b      (b[i]),
                .cin    (w_carry[i]),
                .sum    (sum[i]),
                .cout   (w_carry[i+1])
            );
        end
    endgenerate 

    assign cout = w_carry[WIDTH];
endmodule