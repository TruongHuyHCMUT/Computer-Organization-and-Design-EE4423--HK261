// =============================================================================
// tb_lsu.sv - Testbench for the Load/Store Unit (Milestone 2, Sec. 4.6)
//
// Two phases in one file:
//   Phase 1 (T1..T6) : unit test of the LSU alone (testbench drives i_dmem_rdata)
//   Phase 2 (I0..I4) : LSU + course DMEM round trip (store -> load) against an
//                      independent little-endian byte-array model
// =============================================================================
`timescale 1ns/1ps
module tb_lsu;
  localparam bit STRICT_ADDR = 1'b1;

  localparam logic [2:0] F3_B = 3'b000, F3_H = 3'b001, F3_W = 3'b010,
                         F3_BU = 3'b100, F3_HU = 3'b101;

  // ---------------------------------------------------------------- clock
  logic i_clk = 0;
  always #5 i_clk = ~i_clk;

  // ---------------------------------------------------------------- Phase 1 DUT (stand-alone)
  logic [31:0] i_lsu_addr, i_st_data, i_dmem_rdata;
  logic        i_lsu_wren;
  logic [2:0]  i_lsu_funct3;
  logic [31:0] o_ld_data, o_dmem_addr, o_dmem_wdata;
  logic [3:0]  o_dmem_bmsk;
  logic        o_dmem_wren;

  // [SỬA PORT] Đổi .i_lsu_funct3 -> .i_funct3 để khớp với lsu.sv
  lsu dut (.i_lsu_addr(i_lsu_addr), .i_st_data(i_st_data), .i_lsu_wren(i_lsu_wren),
           .i_funct3(i_lsu_funct3), .i_dmem_rdata(i_dmem_rdata),
           .o_ld_data(o_ld_data), .o_dmem_addr(o_dmem_addr), .o_dmem_wdata(o_dmem_wdata),
           .o_dmem_bmsk(o_dmem_bmsk), .o_dmem_wren(o_dmem_wren));

  int err = 0, total = 0;
  logic [31:0] pat [0:9];
  logic [2:0]  ldf [0:4];
  logic [2:0]  stf [0:2];

  function automatic logic [1:0] pick_off(input logic [2:0] f3, input logic [1:0] r);
    case (f3[1:0])
      2'b00:   pick_off = r;              // byte: any offset
      2'b01:   pick_off = {r[1], 1'b0};   // half: 0 or 2
      default: pick_off = 2'b00;          // word: 0
    endcase
  endfunction

  task automatic fail(input string msg);
    err++;
    if (err <= 25)
      $display("[FAIL] t=%0t %s | f3=%b wren=%b addr=%h st=%h rdata=%h -> ld=%h waddr=%h wdata=%h bmsk=%b wr=%b",
               $time, msg, i_lsu_funct3, i_lsu_wren, i_lsu_addr, i_st_data, i_dmem_rdata,
               o_ld_data, o_dmem_addr, o_dmem_wdata, o_dmem_bmsk, o_dmem_wren);
  endtask

  task automatic check(input logic [31:0] addr, st, rdata, input logic wr, input logic [2:0] f3);
    logic [3:0]  exp_bm;
    logic [31:0] exp_w, exp_ld;
    logic [7:0]  b;
    logic [15:0] h;
    int k;
    i_lsu_addr = addr; i_st_data = st; i_dmem_rdata = rdata; i_lsu_wren = wr; i_lsu_funct3 = f3;
    #1;
    total++;
    // ---- signals common to loads and stores
    if (o_dmem_wren !== wr) fail("o_dmem_wren != i_lsu_wren");
    if (STRICT_ADDR ? (o_dmem_addr !== addr) : (o_dmem_addr[31:2] !== addr[31:2])) fail("o_dmem_addr mismatch");

    if (wr) begin
      // ---- store: byte mask + data aligned to the right lane(s)
      case (f3[1:0])
        2'b00:   begin exp_bm = 4'b0001 << addr[1:0];                 exp_w = {24'b0, st[7:0]}  << (8*addr[1:0]); end
        2'b01:   begin exp_bm = addr[1] ? 4'b1100 : 4'b0011;          exp_w = {16'b0, st[15:0]} << (16*addr[1]);  end
        default: begin exp_bm = 4'b1111;                              exp_w = st; end
      endcase
      if (o_dmem_bmsk !== exp_bm) fail($sformatf("o_dmem_bmsk (exp %b)", exp_bm));
      for (k = 0; k < 4; k++)
        if (exp_bm[k] && o_dmem_wdata[8*k +: 8] !== exp_w[8*k +: 8])
          fail($sformatf("o_dmem_wdata lane %0d (exp %h)", k, exp_w[8*k +: 8]));
    end else begin
      // ---- load: select + extend
      b = rdata[8*addr[1:0] +: 8];
      h = rdata[16*addr[1]  +: 16];
      case (f3)
        F3_B:    exp_ld = {{24{b[7]}},  b};
        F3_BU:   exp_ld = {24'b0, b};
        F3_H:    exp_ld = {{16{h[15]}}, h};
        F3_HU:   exp_ld = {16'b0, h};
        default: exp_ld = rdata;
      endcase
      if (o_ld_data !== exp_ld) fail($sformatf("o_ld_data (exp %h)", exp_ld));
    end
  endtask

`ifndef TB_LSU_NO_DMEM
  // ---------------------------------------------------------------- Phase 2: LSU + DMEM
  localparam logic [31:0] START_ADDR = 32'h8008_0000;   // C-program memory map
  localparam int          ADDR_WIDTH = 16;
  localparam int          SIZE       = 1 << ADDR_WIDTH;

  logic [31:0] m_addr = START_ADDR, m_st = 0, m_dmem_rdata;
  logic        m_wren = 0;
  logic [2:0]  m_f3 = F3_W;
  logic [31:0] m_ld, m_daddr, m_dwdata;
  logic [3:0]  m_dbmsk;
  logic        m_dwren;

  // [SỬA PORT] Đổi .i_lsu_funct3 -> .i_funct3
  lsu dut_it (.i_lsu_addr(m_addr), .i_st_data(m_st), .i_lsu_wren(m_wren),
              .i_funct3(m_f3), .i_dmem_rdata(m_dmem_rdata),
              .o_ld_data(m_ld), .o_dmem_addr(m_daddr), .o_dmem_wdata(m_dwdata),
              .o_dmem_bmsk(m_dbmsk), .o_dmem_wren(m_dwren));

  dmem #(.START_ADDR(START_ADDR), .ADDR_WIDTH(ADDR_WIDTH)) dut_dmem (
    .i_clk(i_clk), .i_addr(m_daddr), .i_wdata(m_dwdata),
    .i_bmsk(m_dbmsk), .i_wren(m_dwren), .o_rdata(m_dmem_rdata));

  logic [7:0] mem [0:SIZE-1];   // reference model: little-endian byte array

  function automatic bit in_range(input logic [31:0] a);
    return (a >= START_ADDR) && ((a - START_ADDR) < SIZE);
  endfunction

  function automatic logic [31:0] mload(input logic [31:0] a, input logic [2:0] f3);
    int off;
    if (!in_range(a)) return 32'h0;            // out-of-range DMEM read returns 0
    off = a - START_ADDR;
    case (f3)
      F3_B:    return {{24{mem[off][7]}}, mem[off]};
      F3_BU:   return {24'b0, mem[off]};
      F3_H:    return {{16{mem[off+1][7]}}, mem[off+1], mem[off]};
      F3_HU:   return {16'b0, mem[off+1], mem[off]};
      default: return {mem[off+3], mem[off+2], mem[off+1], mem[off]};
    endcase
  endfunction

  task automatic mstore(input logic [31:0] a, st, input logic [2:0] f3);
    int off;
    if (in_range(a)) begin
      off = a - START_ADDR;
      mem[off] = st[7:0];
      if (f3[1:0] != 2'b00) mem[off+1] = st[15:8];
      if (f3[1:0] == 2'b10) begin mem[off+2] = st[23:16]; mem[off+3] = st[31:24]; end
    end
  endtask

  task automatic acc(input logic [31:0] a, st, input logic wr, input logic [2:0] f3, input bit do_check = 1);
    logic [31:0] e;
    @(negedge i_clk);
    m_addr = a; m_st = st; m_wren = wr; m_f3 = f3;
    #1;
    if (!wr && do_check) begin
      e = mload(a, f3); total++;
      if (m_ld !== e) begin
        err++;
        if (err <= 25) $display("[FAIL] t=%0t LOAD f3=%b addr=%h -> %h (exp %h)", $time, f3, a, m_ld, e);
      end
    end
    if (wr) begin @(posedge i_clk); mstore(a, st, f3); #1; end
  endtask

  task automatic expect_ld(input logic [31:0] a, input logic [2:0] f3, input logic [31:0] v);
    acc(a, 32'h0, 1'b0, f3, 0); total++;
    if (m_ld !== v) begin
      err++; $display("[FAIL] t=%0t literal LOAD f3=%b addr=%h -> %h (exp %h)", $time, a, m_ld, v);
    end
  endtask

  function automatic logic [31:0] rand_addr(input logic [2:0] f3);
    logic [31:0] a;
    int mode;
    mode = $urandom_range(19, 0);
    if      (mode < 15) a = START_ADDR + ($urandom_range(SIZE/4 - 1, 0) << 2);
    else if (mode < 16) a = START_ADDR;
    else if (mode < 17) a = START_ADDR + SIZE - 4;
    else if (mode < 18) a = START_ADDR + SIZE + ($urandom_range(255, 0) << 2);
    else if (mode < 19) a = START_ADDR - 4 - ($urandom_range(255, 0) << 2);
    else                a = $urandom & 32'hFFFF_FFFC;
    a[1:0] = pick_off(f3, $urandom_range(3, 0));
    return a;
  endfunction
`endif

  initial begin
    int fi, sf, o, p, l, i, k, w, kind, err_p1;
    logic [31:0] rd, a, bases [0:4];
    logic [7:0]  byv [0:5];
    logic [15:0] hv  [0:4];
    logic [2:0]  f3;
    $dumpfile("tb_lsu.vcd"); $dumpvars(0, tb_lsu);
    pat[0] = 32'h0000_0000; pat[1] = 32'hFFFF_FFFF; pat[2] = 32'h8000_0000; pat[3] = 32'h7FFF_FFFF;
    pat[4] = 32'h1234_5678; pat[5] = 32'h8765_4321; pat[6] = 32'hDEAD_BEEF; pat[7] = 32'h0080_FF7F;
    pat[8] = 32'h7F80_00FF; pat[9] = 32'hAAAA_5555;
    ldf[0] = F3_B; ldf[1] = F3_H; ldf[2] = F3_W; ldf[3] = F3_BU; ldf[4] = F3_HU;
    stf[0] = F3_B; stf[1] = F3_H; stf[2] = F3_W;
    byv[0] = 8'h00; byv[1] = 8'h01; byv[2] = 8'h7F; byv[3] = 8'h80; byv[4] = 8'h81; byv[5] = 8'hFF;
    hv[0] = 16'h0000; hv[1] = 16'h0001; hv[2] = 16'h7FFF; hv[3] = 16'h8000; hv[4] = 16'hFFFF;
    bases[0] = 32'h8008_0000; bases[1] = 32'h8400_0000; bases[2] = 32'h8000_0000;
    bases[3] = 32'h0000_0000; bases[4] = 32'hFFFF_FFFC;

    // ===================== Phase 1: LSU alone =====================
    for (fi = 0; fi < 5; fi++) for (o = 0; o < 4; o++) for (p = 0; p < 10; p++)
      if (pick_off(ldf[fi], o[1:0]) == o[1:0])
        check(32'h8008_0100 | o, $urandom, pat[p], 1'b0, ldf[fi]);

    for (l = 0; l < 4; l++) for (p = 0; p < 6; p++) begin
      rd = $urandom; rd[8*l +: 8] = byv[p];
      check(32'h8008_0200 | l, $urandom, rd, 1'b0, F3_B);
      check(32'h8008_0200 | l, $urandom, rd, 1'b0, F3_BU);
    end
    for (l = 0; l < 2; l++) for (p = 0; p < 5; p++) begin
      rd = $urandom; rd[16*l +: 16] = hv[p];
      check(32'h8008_0300 | (l*2), $urandom, rd, 1'b0, F3_H);
      check(32'h8008_0300 | (l*2), $urandom, rd, 1'b0, F3_HU);
    end

    for (sf = 0; sf < 3; sf++) for (o = 0; o < 4; o++) for (p = 0; p < 10; p++)
      if (pick_off(stf[sf], o[1:0]) == o[1:0])
        check(32'h8008_0400 | o, pat[p], $urandom, 1'b1, stf[sf]);

    for (i = 0; i < 5; i++) for (fi = 0; fi < 5; fi++) for (o = 0; o < 4; o++)
      if (pick_off(ldf[fi], o[1:0]) == o[1:0]) begin
        check(bases[i] | o, $urandom, $urandom, 1'b0, ldf[fi]);
        if (fi < 3) check(bases[i] | o, $urandom, $urandom, 1'b1, stf[fi]);
      end

    for (i = 0; i < 200; i++) begin
      f3 = ($urandom_range(2,0) == 0) ? 3'b011 : ($urandom_range(1,0) ? 3'b110 : 3'b111);
      i_lsu_addr = $urandom; i_st_data = $urandom; i_dmem_rdata = $urandom;
      i_lsu_wren = 1'b0; i_lsu_funct3 = f3; #1; total++;
      if (o_dmem_wren !== 1'b0) fail("illegal funct3 load raised o_dmem_wren");
    end

    for (i = 0; i < 100000; i++) begin
      kind = $urandom_range(7, 0);
      if (kind < 5) begin f3 = ldf[kind];     a = $urandom; a[1:0] = pick_off(f3, a[1:0]); check(a, $urandom, $urandom, 1'b0, f3); end
      else          begin f3 = stf[kind - 5]; a = $urandom; a[1:0] = pick_off(f3, a[1:0]); check(a, $urandom, $urandom, 1'b1, f3); end
    end

    err_p1 = err;
    $display("Phase 1 (LSU alone)  : %0d checks so far, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");

`ifndef TB_LSU_NO_DMEM
    // ===================== Phase 2: LSU + DMEM round trip =====================
    for (w = 0; w < SIZE/4; w++) acc(START_ADDR + 4*w, $urandom, 1'b1, F3_W);

    a = START_ADDR + 32'h100;
    acc(a, 32'h1122_3344, 1'b1, F3_W);
    expect_ld(a + 0, F3_BU, 32'h0000_0044);
    expect_ld(a + 1, F3_BU, 32'h0000_0033);
    expect_ld(a + 2, F3_BU, 32'h0000_0022);
    expect_ld(a + 3, F3_BU, 32'h0000_0011);
    acc(a + 1, 32'h0000_00FF, 1'b1, F3_B);
    expect_ld(a, F3_W,      32'h1122_FF44);
    expect_ld(a + 1, F3_B,  32'hFFFF_FFFF);
    expect_ld(a + 1, F3_BU, 32'h0000_00FF);
    acc(a + 2, 32'h0000_BEEF, 1'b1, F3_H);
    expect_ld(a, F3_W,      32'hBEEF_FF44);
    expect_ld(a + 2, F3_H,  32'hFFFF_BEEF);
    expect_ld(a + 2, F3_HU, 32'h0000_BEEF);
    acc(a, 32'h0000_1234, 1'b1, F3_H);
    expect_ld(a, F3_W,      32'hBEEF_1234);
    acc(a + 3, 32'h0000_007F, 1'b1, F3_B);
    expect_ld(a + 3, F3_B,  32'h0000_007F);
    expect_ld(a, F3_W,      32'h7FEF_1234);

    for (i = 0; i < 3; i++) for (k = 0; k < 4; k++)
      if (pick_off(stf[i], k[1:0]) == k[1:0]) begin
        acc(START_ADDR + 32'h200, 32'hA1B2_C3D4, 1'b1, F3_W);
        acc(START_ADDR + 32'h200 + k, 32'h8765_4321 + i, 1'b1, stf[i]);
        for (w = 0; w < 5; w++)
          if (pick_off(ldf[w], k[1:0]) == k[1:0]) acc(START_ADDR + 32'h200 + k, 32'h0, 1'b0, ldf[w]);
        acc(START_ADDR + 32'h200, 32'h0, 1'b0, F3_W);
      end

    for (i = 0; i < 6; i++) begin
      a = (i == 0) ? START_ADDR + SIZE : (i == 1) ? START_ADDR - 4 : (i == 2) ? 32'h0 :
          (i == 3) ? 32'hFFFF_FFFC : (i == 4) ? START_ADDR + 2*SIZE : {4'h2, START_ADDR[27:0]};
      for (w = 0; w < 3; w++) acc(a, 32'hBAD0_BAD0, 1'b1, stf[w]);
      for (w = 0; w < 5; w++) acc(a, 32'h0, 1'b0, ldf[w]);
    end
    for (w = 0; w < SIZE/4; w++) acc(START_ADDR + 4*w, 32'h0, 1'b0, F3_W);

    for (i = 0; i < 150000; i++) begin
      k = $urandom_range(7, 0);
      if (k < 5) begin f3 = ldf[k];     acc(rand_addr(f3), $urandom, 1'b0, f3); end
      else          begin f3 = stf[k - 5]; acc(rand_addr(f3), $urandom, 1'b1, f3); end
    end
    for (w = 0; w < SIZE/4; w++) acc(START_ADDR + 4*w, 32'h0, 1'b0, F3_W);
    $display("Phase 2 (LSU + DMEM) : %0d errors -> %s", err - err_p1, (err - err_p1)==0 ? "PASS" : "FAIL");
`else
    $display("Phase 2 skipped (TB_LSU_NO_DMEM defined)");
`endif

    $display("--------------------------------------------------");
    $display("tb_lsu: %0d checks, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");
    $finish;
  end

  initial begin #800_000_000; $display("[TIMEOUT] tb_lsu"); $finish; end
endmodule
