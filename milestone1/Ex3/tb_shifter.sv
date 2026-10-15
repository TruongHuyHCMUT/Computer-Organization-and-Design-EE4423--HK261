// =============================================================================
// tb_shifter.sv - Self-checking testbench for Exercise 3 (Shifter)
// DUT module name expected: shifter
// Ports: i_data[31:0], i_shamt[4:0], i_mode[1:0], o_data[31:0]
// =============================================================================
`timescale 1ns/1ps
module tb_shifter;
  // Reserved mode (2'b11): spec only demands a "defined safe value".
  // The TB always checks o_data has no X/Z. If your design uses a fixed value
  // (e.g. 0), set CHECK_SAFE_VALUE = 1 and SAFE_VALUE accordingly.
  localparam bit          CHECK_SAFE_VALUE = 1'b0;
  localparam logic [31:0] SAFE_VALUE       = 32'h0000_0000;

  logic [31:0] i_data;
  logic [4:0]  i_shamt;
  logic [1:0]  i_mode;
  logic [31:0] o_data;

  shifter dut (.i_data(i_data), .i_shamt(i_shamt), .i_mode(i_mode), .o_data(o_data));

  int err = 0, total = 0;
  logic [31:0] pat [0:9];

  task automatic check(input logic [31:0] d, input logic [4:0] sh, input logic [1:0] mode);
    logic [31:0] exp_d;
    logic signed [31:0] sd;
    sd = d;
    i_data = d; i_shamt = sh; i_mode = mode;
    #1;
    total++;
    case (mode)
      2'b00:   exp_d = d >> sh;
      2'b01:   exp_d = d << sh;
      2'b10:   exp_d = sd >>> sh;
      default: exp_d = SAFE_VALUE;
    endcase
    if (mode == 2'b11) begin
      if ($isunknown(o_data) || (CHECK_SAFE_VALUE && o_data !== exp_d)) begin
        err++;
        if (err <= 20) $display("[FAIL] t=%0t RESERVED mode: data=%h shamt=%0d -> %h (X/Z or != safe %h)",
                                $time, d, sh, o_data, exp_d);
      end
    end else if (o_data !== exp_d) begin
      err++;
      if (err <= 20)
        $display("[FAIL] t=%0t mode=%b data=%h shamt=%0d | out=%h (exp %h)",
                 $time, mode, d, sh, o_data, exp_d);
    end
  endtask

  initial begin
    int i, j, m, k;
    $dumpfile("tb_shifter.vcd"); $dumpvars(0, tb_shifter);
    pat[0] = 32'h0000_0000; pat[1] = 32'hFFFF_FFFF; pat[2] = 32'h8000_0000;
    pat[3] = 32'h7FFF_FFFF; pat[4] = 32'h0000_0001; pat[5] = 32'hAAAA_AAAA;
    pat[6] = 32'h5555_5555; pat[7] = 32'h1234_5678; pat[8] = 32'hDEAD_BEEF;
    pat[9] = 32'h8000_0001;

    // T1: all patterns x all shift amounts x all 4 modes (exhaustive on shamt/mode)
    for (i = 0; i < 10; i++) for (j = 0; j < 32; j++) for (m = 0; m < 4; m++)
      check(pat[i], j[4:0], m[1:0]);

    // T2: walking one / walking zero, every shamt, every mode
    for (k = 0; k < 32; k++) for (j = 0; j < 32; j++) for (m = 0; m < 4; m++) begin
      check(32'h1 << k,  j[4:0], m[1:0]);
      check(~(32'h1 << k), j[4:0], m[1:0]);
    end

    // T3: random
    for (i = 0; i < 50000; i++)
      check($urandom, $urandom_range(31,0), $urandom_range(3,0));

    $display("--------------------------------------------------");
    $display("tb_shifter: %0d checks, %0d errors -> %s", total, err, err==0 ? "PASS" : "FAIL");
    $finish;
  end
endmodule

