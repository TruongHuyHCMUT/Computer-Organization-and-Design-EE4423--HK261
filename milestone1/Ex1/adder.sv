//                   +-----------------------------------+
// i_a ------------->|                                   |
// i_b ------------->|   32-bit Binary Adder Core        |-----> o_sum [31:0]
// i_sub ----------->|   (Full Adder chain, No +/-)      |
//                   +-----------------------------------+
//                        | carry[31]        | carry[32]
//                        | (Cin to MSB)     | (Cout from MSB)
//                        v                  |
//                      +---+                |
//                      |XOR|                |
//                      +---+                |
//                        |                  |
//                        | (Overflow)       | (Carry)
//                        v                  v
//                      \¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯/
//                       \         MUX        / <------- i_unsigned
//                        \__________________/
//                                  |
//                                  v
//                                o_cout

module adder (
    input logic [31:0]  i_a, i_b, 
    input logic         i_sub, i_unsigned,
    output logic [31:0] o_sum,
    output logic        o_cout
);
    logic   [31:0]  w_sub;
    logic           w_cout, w_cin, w_overflow;
    assign w_sub = {32{i_sub}};
    FA #(.WIDTH(32)) dut_fa (
        .a      (i_a),
        .b      (i_b ^ w_sub),
        .cin    (i_sub),
        .sum    (o_sum),
        .cout   (w_cout),
        .o_cin  (w_cin)
    );

    assign w_overflow = w_cin ^ w_cout;
    assign o_cout = i_unsigned ? w_cout : w_overflow;
endmodule

module fa (
    input logic     a, b, cin,
    output logic    sum, cout
);
    assign sum = a  ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule 

module FA #(
    parameter int WIDTH = 32
) (
    input logic [WIDTH-1:0]     a, b,
    input logic                 cin,
    output logic [WIDTH-1:0]    sum,
    output logic                cout, o_cin
);
///////logic [WIDTH-1:0]   w_carry; Code cũ
    logic [WIDTH : 0] w_carry;   //  Code mới đã sửa

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
    assign o_cin = w_carry[WIDTH-1];
endmodule
