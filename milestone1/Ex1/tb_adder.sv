// =============================================================================
// tb_adder.sv - Self-checking testbench for Exercise 1 (32-bit Adder/Subtractor)
// DUT module name expected: adder
// Ports: i_a, i_b, i_sub, i_unsigned, o_sum, o_cout
// =============================================================================
`timescale 1ns/1ps
module tb_adder;
  localparam bit SUB_COUT_IS_CARRY = 1'b1;

  logic [31:0] i_a, i_b;
  logic        i_sub, i_unsigned;
  logic [31:0] o_sum;
  logic        o_cout;

  adder dut (
    .i_a        (i_a), 
    .i_b        (i_b), 
    .i_sub      (i_sub), 
    .i_unsigned (i_unsigned),
    .o_sum      (o_sum), 
    .o_cout     (o_cout)
  );

  int err = 0, total = 0;
  logic [31:0] corner [0:11];

  task automatic check(input logic [31:0] a, b, input logic sub, uns);
    logic [31:0] b_eff;
    logic [32:0] full;
    logic        carry_exp, overflow_exp, cout_exp;

    i_a = a; i_b = b; i_sub = sub; i_unsigned = uns;
    #1;

    b_eff        = sub ? ~b : b;
    full         = {1'b0, a} + {1'b0, b_eff} + {32'b0, sub};

    // [ĐÃ SỬA] Tính cờ Carry/Borrow (Unsigned)
    carry_exp    = (sub && !SUB_COUT_IS_CARRY) ? ~full[32] : full[32];

    // [ĐÃ SỬA] Tính cờ Overflow (Signed): Cùng dấu cộng ra khác dấu
    overflow_exp = (a[31] == b_eff[31]) && (full[31] != a[31]);

    // [ĐÃ SỬA] Chọn tín hiệu cờ mong đợi khớp với DUT
    cout_exp     = uns ? carry_exp : overflow_exp;

    total++;
    if (o_sum !== full[31:0] || o_cout !== cout_exp) begin
      err++;
      if (err <= 20)
        $display("[FAIL] t=%0t a=%h b=%h sub=%b uns=%b | sum=%h (exp %h) cout=%b (exp %b)",
                 $time, a, b, sub, uns, o_sum, full[31:0], o_cout, cout_exp);
    end
  endtask

  initial begin
    int i, j, k, m, s, u;
    $dumpfile("tb_adder.vcd"); $dumpvars(0, tb_adder);
    corner[0]  = 32'h0000_0000; corner[1]  = 32'h0000_0001;
    corner[2]  = 32'hFFFF_FFFF; corner[3]  = 32'h7FFF_FFFF;
    corner[4]  = 32'h8000_0000; corner[5]  = 32'h8000_0001;
    corner[6]  = 32'h0000_FFFF; corner[7]  = 32'hFFFF_0000;
    corner[8]  = 32'hAAAA_AAAA; corner[9]  = 32'h5555_5555;
    corner[10] = 32'h0000_0002; corner[11] = 32'hFFFF_FFFE;

    // T1: corner x corner x {add,sub} x {signed,unsigned}
    for (i = 0; i < 12; i++) for (j = 0; j < 12; j++)
      for (s = 0; s < 2; s++) for (u = 0; u < 2; u++)
        check(corner[i], corner[j], s[0], u[0]);

    // T2: single-bit operands (carry chain / every bit position)
    for (k = 0; k < 32; k++) for (m = 0; m < 32; m++)
      for (s = 0; s < 2; s++) for (u = 0; u < 2; u++)
        check(32'h1 << k, 32'h1 << m, s[0], u[0]);

    // T3: full carry/borrow propagation: all-ones +/- 1 at every width
    for (k = 0; k < 32; k++) begin
      check((32'h1 << k) - 1, 32'h1, 1'b0, 1'b0);   // 0..01..1 + 1
      check(32'h1 << k,       32'h1, 1'b1, 1'b0);   // 0..10..0 - 1
    end

    // T4: a == b, a == -b
    for (k = 0; k < 200; k++) begin
      logic [31:0] r; r = $urandom;
      check(r, r, 1'b1, 1'b0); check(r, r, 1'b1, 1'b1);
      check(r, ~r + 32'd1, 1'b0, 1'b0);
    end

    // T5: constrained random + fully random
    for (k = 0; k < 50000; k++)
      check($urandom, $urandom, $urandom_range(1,0), $urandom_range(1,0));

    $display("--------------------------------------------------");
    $display("tb_adder: %0d checks, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");
    $finish;
  end
endmodule
