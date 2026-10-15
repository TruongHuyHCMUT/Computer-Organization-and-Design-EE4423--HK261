// =============================================================================
// tb_comparator.sv - Self-checking testbench for Exercise 2 (Magnitude Comparator)
// DUT module name expected: comparator
// Ports: i_a, i_b, i_unsigned, o_eq, o_lt, o_gt
// =============================================================================
`timescale 1ns/1ps
module tb_comparator;
  logic [31:0] i_a, i_b;
  logic        i_unsigned;
  logic        o_eq, o_lt, o_gt;

  comparator dut (.i_a(i_a), .i_b(i_b), .i_unsigned(i_unsigned),
                  .o_eq(o_eq), .o_lt(o_lt), .o_gt(o_gt));

  int err = 0, total = 0;
  logic [31:0] corner [0:11];

  task automatic check(input logic [31:0] a, b, input logic uns);
    logic eq_e, lt_e, gt_e;
    i_a = a; i_b = b; i_unsigned = uns;
    #1;
    eq_e = (a == b);
    lt_e = uns ? (a < b) : ($signed(a) < $signed(b));
    gt_e = uns ? (a > b) : ($signed(a) > $signed(b));
    total++;
    if (o_eq !== eq_e || o_lt !== lt_e || o_gt !== gt_e ||
        (o_eq + o_lt + o_gt) !== 2'd1) begin
      err++;
      if (err <= 20)
        $display("[FAIL] t=%0t a=%h b=%h uns=%b | eq/lt/gt=%b%b%b (exp %b%b%b)",
                 $time, a, b, uns, o_eq, o_lt, o_gt, eq_e, lt_e, gt_e);
    end
  endtask

  initial begin
    int i, j, k;
    logic [31:0] r;
    $dumpfile("tb_comparator.vcd"); $dumpvars(0, tb_comparator);
    corner[0]  = 32'h0000_0000; corner[1]  = 32'h0000_0001;
    corner[2]  = 32'hFFFF_FFFF; corner[3]  = 32'h7FFF_FFFF;
    corner[4]  = 32'h8000_0000; corner[5]  = 32'h8000_0001;
    corner[6]  = 32'h0000_FFFF; corner[7]  = 32'hFFFF_0000;
    corner[8]  = 32'hAAAA_AAAA; corner[9]  = 32'h5555_5555;
    corner[10] = 32'h0000_0002; corner[11] = 32'hFFFF_FFFE;

    // T1: corner x corner, both modes (covers sign-bit handling)
    for (i = 0; i < 12; i++) for (j = 0; j < 12; j++) begin
      check(corner[i], corner[j], 1'b0);
      check(corner[i], corner[j], 1'b1);
    end

    // T2: operands differing in exactly one bit (every bit decides the result)
    for (k = 0; k < 32; k++) for (i = 0; i < 100; i++) begin
      r = $urandom;
      check(r, r ^ (32'h1 << k), 1'b0);
      check(r, r ^ (32'h1 << k), 1'b1);
      check(r ^ (32'h1 << k), r, 1'b0);
      check(r ^ (32'h1 << k), r, 1'b1);
    end

    // T3: equal operands and adjacent values
    for (i = 0; i < 2000; i++) begin
      r = $urandom;
      check(r, r, 1'b0);       check(r, r, 1'b1);
      check(r, r + 32'd1, 1'b0); check(r, r + 32'd1, 1'b1);
      check(r + 32'd1, r, 1'b0); check(r + 32'd1, r, 1'b1);
    end

    // T4: opposite signs
    for (i = 0; i < 2000; i++) begin
      check({1'b0, 31'($urandom)}, {1'b1, 31'($urandom)}, 1'b0);
      check({1'b0, 31'($urandom)}, {1'b1, 31'($urandom)}, 1'b1);
      check({1'b1, 31'($urandom)}, {1'b0, 31'($urandom)}, 1'b0);
      check({1'b1, 31'($urandom)}, {1'b0, 31'($urandom)}, 1'b1);
    end

    // T5: fully random
    for (i = 0; i < 50000; i++)
      check($urandom, $urandom, $urandom_range(1,0));

    $display("--------------------------------------------------");
    $display("tb_comparator: %0d checks, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");
    $finish;
  end
endmodule

