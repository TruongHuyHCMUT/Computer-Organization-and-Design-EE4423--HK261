// =============================================================================
// tb_alu.sv - Self-checking testbench for Exercise 4 (ALU)
// Modified to match RTL author's custom opcode encoding (4'd0 .. 4'd9)
// =============================================================================
`timescale 1ns/1ps
module tb_alu;
  // [SỬA TESTBENCH] Đổi opcode khớp với localparam trong alu.sv của thiết kế
  localparam logic [3:0] ALU_ADD  = 4'd0;
  localparam logic [3:0] ALU_SUB  = 4'd1;
  localparam logic [3:0] ALU_SLL  = 4'd2;
  localparam logic [3:0] ALU_SLT  = 4'd3;
  localparam logic [3:0] ALU_SLTU = 4'd4;
  localparam logic [3:0] ALU_XOR  = 4'd5;
  localparam logic [3:0] ALU_SRL  = 4'd6;
  localparam logic [3:0] ALU_SRA  = 4'd7;
  localparam logic [3:0] ALU_OR   = 4'd8;
  localparam logic [3:0] ALU_AND  = 4'd9;

  localparam bit         CHECK_SAFE_VALUE = 1'b0;
  localparam logic [31:0] SAFE_VALUE       = 32'h0000_0000;

  logic [31:0] i_op_a, i_op_b;
  logic [3:0]  i_alu_op;
  logic [31:0] o_alu_data;

  alu dut (
    .i_op_a     (i_op_a), 
    .i_op_b     (i_op_b), 
    .i_alu_op   (i_alu_op), 
    .o_alu_data (o_alu_data)
  );

  int err = 0, total = 0;
  logic [31:0] corner [0:11];

  function automatic bit is_valid(input logic [3:0] op);
    return (op==ALU_ADD)||(op==ALU_SUB)||(op==ALU_SLT)||(op==ALU_SLTU)||(op==ALU_XOR)||
           (op==ALU_OR)||(op==ALU_AND)||(op==ALU_SLL)||(op==ALU_SRL)||(op==ALU_SRA);
  endfunction

  function automatic logic [31:0] alu_ref(input logic [31:0] a, b, input logic [3:0] op);
    logic signed [31:0] sa, sb;
    sa = a; sb = b;
    case (op)
      ALU_ADD:  alu_ref = a + b;
      ALU_SUB:  alu_ref = a - b;
      ALU_SLT:  alu_ref = (sa < sb) ? 32'd1 : 32'd0;
      ALU_SLTU: alu_ref = (a < b)   ? 32'd1 : 32'd0;
      ALU_XOR:  alu_ref = a ^ b;
      ALU_OR:   alu_ref = a | b;
      ALU_AND:  alu_ref = a & b;
      ALU_SLL:  alu_ref = a << b[4:0];
      ALU_SRL:  alu_ref = a >> b[4:0];
      ALU_SRA:  alu_ref = sa >>> b[4:0];
      default:  alu_ref = SAFE_VALUE;
    endcase
  endfunction

  task automatic check(input logic [31:0] a, b, input logic [3:0] op);
    logic [31:0] exp_d;
    i_op_a = a; i_op_b = b; i_alu_op = op;
    #1;
    total++;
    exp_d = alu_ref(a, b, op);
    if (is_valid(op)) begin
      if (o_alu_data !== exp_d) begin
        err++;
        if (err <= 20)
          $display("[FAIL] t=%0t op=%d a=%h b=%h | out=%h (exp %h)", $time, op, a, b, o_alu_data, exp_d);
      end
    end else if ($isunknown(o_alu_data) || (CHECK_SAFE_VALUE && o_alu_data !== SAFE_VALUE)) begin
      err++;
      if (err <= 20)
        $display("[FAIL] t=%0t UNUSED op=%d a=%h b=%h | out=%h (X/Z or != safe)", $time, op, a, b, o_alu_data);
    end
  endtask

  initial begin
    int i, j, o, k;
    $dumpfile("tb_alu.vcd"); $dumpvars(0, tb_alu);
    corner[0]  = 32'h0000_0000; corner[1]  = 32'h0000_0001;
    corner[2]  = 32'hFFFF_FFFF; corner[3]  = 32'h7FFF_FFFF;
    corner[4]  = 32'h8000_0000; corner[5]  = 32'h8000_0001;
    corner[6]  = 32'h0000_001F; corner[7]  = 32'hFFFF_FFE0;
    corner[8]  = 32'hAAAA_AAAA; corner[9]  = 32'h5555_5555;
    corner[10] = 32'h0000_0020; corner[11] = 32'hDEAD_BEEF;

    // T1: all 16 opcodes (valid + unused) x corner x corner
    for (o = 0; o < 16; o++) for (i = 0; i < 12; i++) for (j = 0; j < 12; j++)
      check(corner[i], corner[j], o[3:0]);

    // T2: shifts with every shamt, and upper bits of b set (only b[4:0] may be used)
    for (k = 0; k < 32; k++) for (i = 0; i < 12; i++) begin
      check(corner[i], k,                                       ALU_SLL);
      check(corner[i], k,                                       ALU_SRL);
      check(corner[i], k,                                       ALU_SRA);
      check(corner[i], {$urandom_range(26'h3FFFFFF,0), k[4:0]}, ALU_SLL);
      check(corner[i], {$urandom_range(26'h3FFFFFF,0), k[4:0]}, ALU_SRL);
      check(corner[i], {$urandom_range(26'h3FFFFFF,0), k[4:0]}, ALU_SRA);
    end

    // T3: SLT vs SLTU on sign-boundary operands (bits[31:1] must be 0)
    for (i = 0; i < 12; i++) for (j = 0; j < 12; j++) begin
      check(corner[i], corner[j], ALU_SLT);
      check(corner[i], corner[j], ALU_SLTU);
    end

    // T4: add/sub overflow & wrap-around, a-a, a+(-a)
    for (i = 0; i < 500; i++) begin
      logic [31:0] r; r = $urandom;
      check(r, r, ALU_SUB); check(r, ~r + 32'd1, ALU_ADD);
      check(r, 32'h7FFF_FFFF, ALU_ADD); check(r, 32'h8000_0000, ALU_SUB);
    end

    // T5: random operands x random opcode
    for (i = 0; i < 100000; i++)
      check($urandom, $urandom, $urandom_range(15,0));

    $display("--------------------------------------------------");
    $display("tb_alu: %0d checks, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");
    $finish;
  end
endmodule
