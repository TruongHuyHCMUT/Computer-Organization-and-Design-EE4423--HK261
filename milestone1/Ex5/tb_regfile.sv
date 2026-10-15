// =============================================================================
// tb_regfile.sv - Self-checking testbench for Exercise 5 (Register File)
// DUT module name expected: regfile
// Ports: clk, rst_n, i_rs1_addr, i_rs2_addr, i_rd_addr, i_rd_data, i_rd_wren,
//        o_rs1_data, o_rs2_data
// =============================================================================
`timescale 1ns/1ps
module tb_regfile;
  logic        i_clk = 0, i_rstn = 0;
  logic [4:0]  i_rs1_addr = 0, i_rs2_addr = 0, i_rd_addr = 0;
  logic [31:0] i_rd_data = 0;
  logic        i_rd_wren = 0;
  logic [31:0] o_rs1_data, o_rs2_data;

  // Connected to exact port names in regfile.sv
  regfile dut (
    .clk        (i_clk), 
    .rst_n      (i_rstn),
    .i_rs1_addr (i_rs1_addr), 
    .i_rs2_addr (i_rs2_addr),
    .i_rd_addr  (i_rd_addr), 
    .i_rd_data  (i_rd_data), 
    .i_rd_wren  (i_rd_wren),
    .o_rs1_data (o_rs1_data), 
    .o_rs2_data (o_rs2_data)
  );

  always #5 i_clk = ~i_clk;   // 100 MHz, posedge at 5, 15, ...

  int err = 0, total = 0;
  logic [31:0] m [0:31];      // reference model

  function automatic logic [31:0] mrd(input logic [4:0] a);
    return (a == 5'd0) ? 32'h0 : m[a];
  endfunction

  task automatic chk(input string tag);
    total++;
    if (o_rs1_data !== mrd(i_rs1_addr) || o_rs2_data !== mrd(i_rs2_addr)) begin
      err++;
      if (err <= 20)
        $display("[FAIL] t=%0t %s | rs1[x%0d]=%h (exp %h)  rs2[x%0d]=%h (exp %h)", $time, tag,
                 i_rs1_addr, o_rs1_data, mrd(i_rs1_addr), i_rs2_addr, o_rs2_data, mrd(i_rs2_addr));
    end
  endtask

  // one clock cycle: drive @negedge, check before edge, update model at edge, check after
  task automatic cyc(input logic [4:0] rs1, rs2, rd, input logic [31:0] wd, input logic wr);
    @(negedge i_clk);
    i_rs1_addr = rs1; i_rs2_addr = rs2; i_rd_addr = rd; i_rd_data = wd; i_rd_wren = wr;
    #1 chk("pre-edge ");
    @(posedge i_clk);
    if (i_rstn && wr && rd != 5'd0) m[rd] = wd;
    #1 chk("post-edge");
  endtask

  // asynchronous reset asserted in the middle of a clock phase
  task automatic async_reset_check;
    int k;
    @(negedge i_clk);
    #1 i_rstn = 0;
    for (k = 0; k < 32; k++) m[k] = 32'h0;
    for (k = 0; k < 32; k++) begin
      i_rs1_addr = k[4:0]; i_rs2_addr = 5'd31 - k[4:0];
      #0.1 chk("async-rst ");         // no clock edge in between
    end
    @(negedge i_clk);                    // at least one posedge happens while in reset
    i_rd_wren = 0;                       // no stray write after reset is released
    i_rstn = 1;
  endtask

  initial begin
    int i, k;
    logic [31:0] r;
    $dumpfile("tb_regfile.vcd"); $dumpvars(0, tb_regfile);
    for (k = 0; k < 32; k++) m[k] = 32'h0;

    // T1: power-up reset, writes ignored while reset is low
    #12;
    cyc(5'd1, 5'd2, 5'd1, 32'hFFFF_FFFF, 1'b1);   // i_rstn=0 -> must stay 0
    cyc(5'd1, 5'd2, 5'd2, 32'hFFFF_FFFF, 1'b1);
    @(negedge i_clk) i_rstn = 1;

    // T2: write every register x1..x31 with a unique value, read back via both ports
    for (i = 1; i < 32; i++) cyc(5'd0, 5'd0, i[4:0], 32'hA000_0000 | (i << 8) | i, 1'b1);
    for (i = 0; i < 32; i++) cyc(i[4:0], 5'd31 - i[4:0], 5'd0, 32'h0, 1'b0);

    // T3: x0 behaviour
    cyc(5'd0, 5'd0, 5'd0, 32'hDEAD_BEEF, 1'b1);   // write to x0 ignored
    cyc(5'd0, 5'd0, 5'd0, 32'hFFFF_FFFF, 1'b1);
    cyc(5'd0, 5'd5, 5'd0, 32'h1234_5678, 1'b1);

    // T4: write enable low -> no write
    cyc(5'd3, 5'd4, 5'd3, 32'hBAD0_BAD0, 1'b0);
    cyc(5'd3, 5'd4, 5'd4, 32'hBAD1_BAD1, 1'b0);

    // T5: both ports same address; read-during-write
    cyc(5'd7, 5'd7, 5'd7, 32'h0000_0007, 1'b1);
    cyc(5'd7, 5'd7, 5'd7, 32'h7777_7777, 1'b1);
    cyc(5'd7, 5'd8, 5'd8, 32'h8888_8888, 1'b1);
    cyc(5'd8, 5'd7, 5'd7, 32'h0, 1'b1);           // write zero
    cyc(5'd7, 5'd8, 5'd7, 32'hFFFF_FFFF, 1'b1);   // all ones
    cyc(5'd31, 5'd31, 5'd31, 32'hCAFE_F00D, 1'b1);// highest register

    // T6: purely combinational read - sweep address inside one clock phase
    @(negedge i_clk);
    i_rd_wren = 0;
    for (k = 0; k < 32; k++) begin
      i_rs1_addr = k[4:0]; i_rs2_addr = 5'd31 - k[4:0];
      #0.05 chk("async-read");
      #0.05;
    end

    // T7: asynchronous reset mid-cycle (with wren high) clears everything
    cyc(5'd1, 5'd2, 5'd9, 32'h9999_9999, 1'b1);
    i_rd_wren = 1;
    async_reset_check();
    cyc(5'd9, 5'd10, 5'd10, 32'h1010_1010, 1'b1);
    cyc(5'd9, 5'd10, 5'd9,  32'h0909_0909, 1'b1);

    // T8: constrained-random traffic with occasional async resets
    for (i = 0; i < 20000; i++) begin
      r = $urandom;
      cyc($urandom_range(31,0), $urandom_range(31,0), $urandom_range(31,0), $urandom, r[0] | r[1]);
      if ($urandom_range(499,0) == 0) async_reset_check();
    end

    $display("--------------------------------------------------");
    $display("tb_regfile: %0d checks, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");
    $finish;
  end

  initial begin #50_000_000; $display("[TIMEOUT] tb_regfile"); $finish; end
endmodule
