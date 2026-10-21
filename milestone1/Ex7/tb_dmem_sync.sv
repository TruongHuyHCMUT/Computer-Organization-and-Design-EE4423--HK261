// =============================================================================
// tb_dmem_sync.sv - Self-checking testbench for Exercise 7 (Data memory, sync read)
// DUT module name expected: dmem (parameters START_ADDR, ADDR_WIDTH)
// Ports: i_clk, i_addr, i_wdata, i_bmsk, i_rden, i_wren, o_rdata
// RW_POLICY = 0: read-before-write (o_rdata gets OLD data, matches M10K behaviour)
// =============================================================================
`timescale 1ns/1ps
module tb_dmem_sync;
  localparam logic [31:0] START_ADDR = 32'h1000_0000;
  localparam int          ADDR_WIDTH = 10;
  localparam int          SIZE       = 1 << ADDR_WIDTH;
  localparam int          RW_POLICY  = 0;     // 0 = read-before-write (old data)

  logic        i_clk = 0;
  logic [31:0] i_addr = START_ADDR, i_wdata = 0;
  logic [3:0]  i_bmsk = 0;
  logic        i_rden = 0, i_wren = 0;
  logic [31:0] o_rdata;

  // [ĐÃ SỬA PORT] Đổi dmem_sync -> dmem để khớp với file dmem.sv
  dmem #(.START_ADDR(START_ADDR), .ADDR_WIDTH(ADDR_WIDTH)) dut (
    .i_clk(i_clk), .i_addr(i_addr), .i_wdata(i_wdata), .i_bmsk(i_bmsk),
    .i_rden(i_rden), .i_wren(i_wren), .o_rdata(o_rdata));

  always #5 i_clk = ~i_clk;

  int err = 0, total = 0;
  logic [7:0]  mem [0:SIZE-1];
  logic [31:0] exp_rdata = 32'h0;
  bit          exp_valid = 0;      // o_rdata is undefined until the first read

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
    if (exp_valid) begin
      total++;
      if (o_rdata !== exp_rdata) begin
        err++;
        if (err <= 20)
          $display("[FAIL] t=%0t %s addr=%h rden=%b wren=%b | rdata=%h (exp %h)",
                   $time, tag, i_addr, i_rden, i_wren, o_rdata, exp_rdata);
      end
    end
  endtask

  // One clock cycle. Before the edge o_rdata must be unchanged (1-cycle latency);
  // after the edge it must equal the model.
  task automatic cyc(input logic [31:0] a, w, input logic [3:0] bm, input logic rden, wren);
    @(negedge i_clk);
    i_addr = a; i_wdata = w; i_bmsk = bm; i_rden = rden; i_wren = wren;
    #1 chk("pre-edge ");
    @(posedge i_clk);
    if (rden) begin
      if (wren && RW_POLICY == 1) begin mwrite(a, w, bm); exp_rdata = mword(a); end
      else begin exp_rdata = mword(a); if (wren) mwrite(a, w, bm); end
      exp_valid = 1;
    end else if (wren) mwrite(a, w, bm);
    #1 chk("post-edge");
  endtask

  task automatic expect_read(input logic [31:0] a, input logic [31:0] v);
    cyc(a, $urandom, $urandom, 1'b1, 1'b0);
    total++;
    if (o_rdata !== v) begin
      err++; $display("[FAIL] t=%0t literal check addr=%h | rdata=%h (exp %h)", $time, a, o_rdata, v);
    end
  endtask

  initial begin
    int i, w, k;
    logic [31:0] a, r, oor [0:5];
    $dumpfile("tb_dmem_sync.vcd"); $dumpvars(0, tb_dmem_sync);

    // T0: initialise all words (write only, rden=0)
    for (w = 0; w < SIZE/4; w++) cyc(START_ADDR + 4*w, $urandom, 4'hF, 1'b0, 1'b1);

    // T1: registered read: one-cycle latency, data valid after the edge
    cyc(START_ADDR + 32'h10, 32'hDEAD_BEEF, 4'hF, 1'b0, 1'b1);
    expect_read(START_ADDR + 32'h10, 32'hDEAD_BEEF);

    // T2: o_rdata holds when rden=0 (address and write traffic change meanwhile)
    cyc(START_ADDR + 32'h20, 32'h0, 4'h0, 1'b0, 1'b0);
    cyc(START_ADDR + 32'h24, 32'h5555_AAAA, 4'hF, 1'b0, 1'b1);
    cyc(START_ADDR + 32'h28, 32'h0, 4'h0, 1'b0, 1'b0);
    cyc(START_ADDR + 32'h10, 32'h0, 4'h0, 1'b0, 1'b0);

    // T3: little-endian + byte lanes with literal expectations
    a = START_ADDR + 32'h100;
    cyc(a, 32'h1234_5678, 4'hF,   1'b0, 1'b1); expect_read(a, 32'h1234_5678);
    cyc(a, 32'hFFFF_FFFF, 4'b0001, 1'b0, 1'b1); expect_read(a, 32'h1234_56FF);
    cyc(a, 32'hAAAA_AAAA, 4'b1000, 1'b0, 1'b1); expect_read(a, 32'hAA34_56FF);
    cyc(a, 32'h0000_BB00, 4'b0010, 1'b0, 1'b1); expect_read(a, 32'hAA34_BBFF);
    cyc(a, 32'h00CC_0000, 4'b0100, 1'b0, 1'b1); expect_read(a, 32'hAACC_BBFF);

    // T4: all 16 byte masks
    for (k = 0; k < 16; k++) begin
      cyc(START_ADDR + 32'h40, 32'hA1B2_C3D4, 4'hF, 1'b0, 1'b1);
      cyc(START_ADDR + 32'h40, 32'h1122_3344, k[3:0], 1'b0, 1'b1);
      cyc(START_ADDR + 32'h40, 32'h0, 4'h0, 1'b1, 1'b0);
    end

    // T5: simultaneous read + write to the same word (documented RW_POLICY)
    cyc(START_ADDR + 32'h60, 32'h0A0A_0A0A, 4'hF, 1'b0, 1'b1);
    cyc(START_ADDR + 32'h60, 32'h5555_5555, 4'hF, 1'b1, 1'b1);        // full word
    cyc(START_ADDR + 32'h60, 32'hFFFF_FFFF, 4'b0011, 1'b1, 1'b1);    // partial mask
    cyc(START_ADDR + 32'h60, 32'h0, 4'h0, 1'b1, 1'b0);                // see final content
    expect_read(START_ADDR + 32'h60, 32'h5555_FFFF);                  // final content: lanes 1:0 = FFFF

    // T6: boundaries and out-of-range (read -> 0 and o_rdata updated, write ignored)
    cyc(START_ADDR, 32'h1111_1111, 4'hF, 1'b0, 1'b1);
    cyc(START_ADDR + SIZE - 4, 32'h2222_2222, 4'hF, 1'b0, 1'b1);
    expect_read(START_ADDR, 32'h1111_1111);
    expect_read(START_ADDR + SIZE - 4, 32'h2222_2222);
    oor[0] = START_ADDR + SIZE;        oor[1] = START_ADDR - 4;
    oor[2] = 32'h0;                    oor[3] = 32'hFFFF_FFFC;
    oor[4] = START_ADDR + 2*SIZE + 4; oor[5] = {4'h2, START_ADDR[27:0]};
    for (i = 0; i < 6; i++) begin
      cyc(oor[i], 32'hBAD0_BAD0, 4'hF, 1'b0, 1'b1);                  // write ignored
      expect_read(oor[i], 32'h0);                                     // read returns 0
      expect_read(START_ADDR + 32'h4, mword(START_ADDR + 32'h4));    // no aliasing
    end
    for (w = 0; w < SIZE/4; w++) cyc(START_ADDR + 4*w, 32'h0, 4'h0, 1'b1, 1'b0);   // full scan

    // T7: random traffic (80% in-range, 20% boundary/out-of-range)
    for (i = 0; i < 40000; i++) begin
      r = $urandom;
      if (r[7:0] < 8'd205)      a = START_ADDR + ($urandom_range(SIZE/4 - 1, 0) << 2);
      else case (r[10:8])
        3'd0: a = START_ADDR + SIZE;       3'd1: a = START_ADDR - 4;
        3'd2: a = START_ADDR + SIZE - 4;   3'd3: a = START_ADDR;
        3'd4: a = $urandom & 32'hFFFF_FFFC; default: a = START_ADDR + SIZE + ($urandom_range(255,0) << 2);
      endcase
      cyc(a, $urandom, $urandom, r[12], r[13]);
    end
    for (w = 0; w < SIZE/4; w++) cyc(START_ADDR + 4*w, 32'h0, 4'h0, 1'b1, 1'b0);

    $display("--------------------------------------------------");
    $display("tb_dmem_sync: %0d checks, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");
    $finish;
  end

  initial begin #400_000_000; $display("[TIMEOUT] tb_dmem_sync"); $finish; end
endmodule
