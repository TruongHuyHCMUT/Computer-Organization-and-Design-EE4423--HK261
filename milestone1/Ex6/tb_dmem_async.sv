// =============================================================================
// tb_dmem_async.sv - Self-checking testbench for Exercise 6 (Data memory, async read)
// DUT module name expected: dmem (parameters START_ADDR, ADDR_WIDTH)
// Ports: i_clk, i_addr, i_wdata, i_bmsk, i_wren, o_rdata
// Assumption: accesses are word-aligned; i_addr[1:0] is ignored for word selection.
// =============================================================================
`timescale 1ns/1ps
module tb_dmem_async;
  localparam logic [31:0] START_ADDR = 32'h1000_0000;
  localparam int          ADDR_WIDTH = 10;
  localparam int          SIZE       = 1 << ADDR_WIDTH;     // bytes

  logic        i_clk = 0;
  logic [31:0] i_addr = START_ADDR, i_wdata = 0;
  logic [3:0]  i_bmsk = 0;
  logic        i_wren = 0;
  logic [31:0] o_rdata;

  // [SỬA PORT] Đổi dmem_async -> dmem để khớp với file dmem.sv
  dmem #(.START_ADDR(START_ADDR), .ADDR_WIDTH(ADDR_WIDTH)) dut (
    .i_clk(i_clk), .i_addr(i_addr), .i_wdata(i_wdata),
    .i_bmsk(i_bmsk), .i_wren(i_wren), .o_rdata(o_rdata));

  always #5 i_clk = ~i_clk;

  int err = 0, total = 0;
  bit init_done = 0;
  logic [7:0] mem [0:SIZE-1];      // reference model (byte array)

  function automatic bit in_range(input logic [31:0] a);
    return (a >= START_ADDR) && ((a - START_ADDR) < SIZE);
  endfunction

  function automatic logic [31:0] mword(input logic [31:0] a);
    int off;
    if (!in_range(a)) return 32'h0;
    off = (a - START_ADDR) & ~32'd3;
    return {mem[off+3], mem[off+2], mem[off+1], mem[off]};
  endfunction

  task automatic mwrite(input logic [31:0] a, w, input logic [3:0] bm);
    int off, b;
    if (in_range(a)) begin
      off = (a - START_ADDR) & ~32'd3;
      for (b = 0; b < 4; b++) if (bm[b]) mem[off+b] = w[8*b +: 8];
    end
  endtask

  task automatic chk(input string tag);
    logic [31:0] e;
    e = mword(i_addr);
    total++;
    if (o_rdata !== e) begin
      err++;
      if (err <= 20) $display("[FAIL] t=%0t %s addr=%h | rdata=%h (exp %h)", $time, tag, i_addr, o_rdata, e);
    end
  endtask

  // write cycle: old value visible before edge, new value after edge
  task automatic wr(input logic [31:0] a, w, input logic [3:0] bm);
    @(negedge i_clk);
    i_addr = a; i_wdata = w; i_bmsk = bm; i_wren = 1;
    #1 if (init_done) chk("wr pre-edge ");
    @(posedge i_clk);
    mwrite(a, w, bm);
    #1 chk("wr post-edge");
  endtask

  // read (async): no clock needed
  task automatic rd(input logic [31:0] a);
    @(negedge i_clk);
    i_addr = a; i_wren = 0; i_wdata = $urandom; i_bmsk = $urandom;
    #1 chk("rd");
  endtask

  task automatic expect_word(input logic [31:0] a, input logic [31:0] v);
    rd(a);
    if (o_rdata !== v) begin
      err++; $display("[FAIL] t=%0t literal check addr=%h | rdata=%h (exp %h)", $time, a, o_rdata, v);
    end
  endtask

  task automatic scan_all;
    int w;
    for (w = 0; w < SIZE/4; w++) rd(START_ADDR + 4*w);
  endtask

  initial begin
    int i, w, k;
    logic [31:0] a, r;
    logic [31:0] oor [0:7];
    $dumpfile("tb_dmem_async.vcd"); $dumpvars(0, tb_dmem_async);

    // T0: initialise the whole memory (contents are undefined at power-up)
    for (w = 0; w < SIZE/4; w++) wr(START_ADDR + 4*w, $urandom, 4'hF);
    init_done = 1;
    scan_all();

    // T1: boundaries - first word, last word, first/last outside
    wr(START_ADDR,            32'h1111_1111, 4'hF); rd(START_ADDR);
    wr(START_ADDR + SIZE - 4, 32'h2222_2222, 4'hF); rd(START_ADDR + SIZE - 4);
    wr(START_ADDR + SIZE,     32'h3333_3333, 4'hF); rd(START_ADDR + SIZE);     // OOR: ignored, reads 0
    wr(START_ADDR - 4,        32'h4444_4444, 4'hF); rd(START_ADDR - 4);        // OOR
    expect_word(START_ADDR, 32'h1111_1111);
    expect_word(START_ADDR + SIZE - 4, 32'h2222_2222);
    expect_word(START_ADDR + SIZE, 32'h0);
    expect_word(START_ADDR - 4, 32'h0);

    // T2: little-endian + byte lanes with literal expectations (address 0x1000_0100)
    a = START_ADDR + 32'h100;
    wr(a, 32'h1234_5678, 4'b1111); expect_word(a, 32'h1234_5678);
    wr(a, 32'hFFFF_FFFF, 4'b0001); expect_word(a, 32'h1234_56FF);   // lane 0 = byte [7:0]
    wr(a, 32'hAAAA_AAAA, 4'b1000); expect_word(a, 32'hAA34_56FF);   // lane 3 = byte [31:24]
    wr(a, 32'h0000_BB00, 4'b0010); expect_word(a, 32'hAA34_BBFF);   // lane 1
    wr(a, 32'h00CC_0000, 4'b0100); expect_word(a, 32'hAACC_BBFF);   // lane 2

    // T3: all 16 byte masks over a known word
    for (k = 0; k < 16; k++) begin
      wr(START_ADDR + 32'h40, 32'hA1B2_C3D4, 4'hF);
      wr(START_ADDR + 32'h40, 32'h1122_3344, k[3:0]);
      rd(START_ADDR + 32'h40);
    end
    wr(START_ADDR + 32'h44, 32'hCAFE_BABE, 4'hF);
    wr(START_ADDR + 32'h44, 32'h0BAD_F00D, 4'b0000); expect_word(START_ADDR + 32'h44, 32'hCAFE_BABE);

    // T4: write disabled -> no change even with mask=F
    @(negedge i_clk); i_addr = START_ADDR + 32'h48; i_wdata = 32'hFFFF_FFFF; i_bmsk = 4'hF; i_wren = 0;
    @(posedge i_clk); #1 chk("wren=0");
    rd(START_ADDR + 32'h48);

    // T5: out-of-range writes must not alias into the valid region; reads return 0
    oor[0] = 32'h0;                     oor[1] = 32'hFFFF_FFFC;
    oor[2] = START_ADDR + SIZE;         oor[3] = START_ADDR + SIZE + 4;
    oor[4] = START_ADDR + 2*SIZE + 4;   oor[5] = START_ADDR - 4;
    oor[6] = START_ADDR - SIZE;         oor[7] = {4'h2, START_ADDR[27:0]};   // upper bits differ
    for (i = 0; i < 8; i++) begin
      wr(oor[i], 32'hBAD0_BAD0, 4'hF);
      rd(oor[i]);
    end
    scan_all();                          // whole memory still equals the model

    // T6: purely combinational read - sweep addresses inside a single clock phase
    @(negedge i_clk); i_wren = 0;
    for (w = 0; w < 16; w++) begin
      i_addr = START_ADDR + 4*w;
      #0.05 chk("async-read"); #0.05;
    end

    // T7: random traffic (80% in-range, 20% boundary/out-of-range)
    for (i = 0; i < 30000; i++) begin
      r = $urandom;
      if (r[7:0] < 8'd205)      a = START_ADDR + ($urandom_range(SIZE/4 - 1, 0) << 2);
      else case (r[10:8])
        3'd0: a = START_ADDR + SIZE;       3'd1: a = START_ADDR - 4;
        3'd2: a = START_ADDR + SIZE - 4;   3'd3: a = START_ADDR;
        3'd4: a = $urandom & 32'hFFFF_FFFC; default: a = START_ADDR + SIZE + ($urandom_range(255,0) << 2);
      endcase
      if (r[12]) wr(a, $urandom, $urandom); else rd(a);
    end
    scan_all();

    $display("--------------------------------------------------");
    $display("tb_dmem_async: %0d checks, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");
    $finish;
  end

  initial begin #200_000_000; $display("[TIMEOUT] tb_dmem_async"); $finish; end
endmodule
