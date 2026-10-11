// Testbench for vending_machine
// Validates functionality against Milestone 1 specifications and Figure 2 waveforms

`timescale 1ns / 1ps

module tb_vending_machine;

  // ---------------------------------------------------------------------------
  // Clock and DUT Signals
  // ---------------------------------------------------------------------------
  logic       clk;
  logic       nickle;
  logic       dime;
  logic       quarter;
  logic       soda;
  logic [2:0] change;

  int test_pass_count = 0;
  int test_fail_count = 0;

  // ---------------------------------------------------------------------------
  // Instantiate DUT
  // ---------------------------------------------------------------------------
  vending_machine dut (
    .i_clk     (clk),
    .i_nickle  (nickle),
    .i_dime    (dime),
    .i_quarter (quarter),
    .o_soda    (soda),
    .o_change  (change)
  );

  // ---------------------------------------------------------------------------
  // Clock Generation: Period = 20ns (50 MHz)
  // ---------------------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  // ---------------------------------------------------------------------------
  // Helper Tasks
  // ---------------------------------------------------------------------------
  // Insert a coin for exactly 1 clock cycle (aligned with clock edge)
  task automatic insert_nickle();
    @(posedge clk);
    #1;
    nickle  = 1'b1;
    dime    = 1'b0;
    quarter = 1'b0;
    @(posedge clk);
    #1;
    nickle  = 1'b0;
  endtask

  task automatic insert_dime();
    @(posedge clk);
    #1;
    nickle  = 1'b0;
    dime    = 1'b1;
    quarter = 1'b0;
    @(posedge clk);
    #1;
    dime    = 1'b0;
  endtask

  task automatic insert_quarter();
    @(posedge clk);
    #1;
    nickle  = 1'b0;
    dime    = 1'b0;
    quarter = 1'b1;
    @(posedge clk);
    #1;
    quarter = 1'b0;
  endtask

  task automatic wait_cycles(input int n);
    repeat (n) begin
      @(posedge clk);
      #1;
      nickle  = 1'b0;
      dime    = 1'b0;
      quarter = 1'b0;
    end
  endtask

  // Check expected outputs
  task automatic check_outputs(
    input string      test_name,
    input logic       expected_soda,
    input logic [2:0] expected_change
  );
    @(negedge clk); // sample in the middle of the cycle
    if (soda === expected_soda && change === expected_change) begin
      $display("[PASS] %s: o_soda = %b, o_change = %b (%0d cents)",
               test_name, soda, change, change * 5);
      test_pass_count++;
    end else begin
      $error("[FAIL] %s: Expected (o_soda=%b, o_change=%b), Got (o_soda=%b, o_change=%b)",
             test_name, expected_soda, expected_change, soda, change);
      test_fail_count++;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Main Test Sequence
  // ---------------------------------------------------------------------------
  initial begin
    // Setup VCD dumping
    $dumpfile("vending_machine.vcd");
    $dumpvars(0, tb_vending_machine);

    // Initial inputs
    nickle  = 1'b0;
    dime    = 1'b0;
    quarter = 1'b0;

    $display("==================================================================");
    $display("       STARTING VENDING MACHINE SYSTEMVERILOG TESTBENCH           ");
    $display("==================================================================");

    // Initial idle period
    wait_cycles(2);
    check_outputs("Initial Idle", 1'b0, 3'b000);

    // -------------------------------------------------------------------------
    // TEST 1: Exact waveform from Figure 2 - Transaction 1
    // Dime (10c) -> 1 Idle Cycle -> Quarter (25c) -> Dispense Soda + 15c change (011)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 1: Figure 2 Transaction 1 (10c + wait + 25c = 35c) ---");
    insert_dime();       // Balance: 10c
    check_outputs("After Dime (10c)", 1'b0, 3'b000);

    wait_cycles(1);      // Idle cycle
    check_outputs("During Idle (hold 10c)", 1'b0, 3'b000);

    insert_quarter();    // Balance: 10c + 25c = 35c -> triggers dispense
    check_outputs("Dispense Soda + 15c Change (35c - 20c)", 1'b1, 3'b011);

    wait_cycles(1);      // Verify return to idle (o_soda = 0, o_change = 0)
    check_outputs("Return to Idle after dispense", 1'b0, 3'b000);

    // -------------------------------------------------------------------------
    // TEST 2: Exact waveform from Figure 2 - Transaction 2
    // Nickle (5c) -> Dime (10c) -> Quarter (25c) -> Dispense Soda + 20c change (100)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 2: Figure 2 Transaction 2 (5c + 10c + 25c = 40c) ---");
    insert_nickle();     // Balance: 5c
    check_outputs("After Nickle (5c)", 1'b0, 3'b000);

    insert_dime();       // Balance: 5c + 10c = 15c
    check_outputs("After Dime (15c)", 1'b0, 3'b000);

    insert_quarter();    // Balance: 15c + 25c = 40c -> triggers dispense
    check_outputs("Dispense Soda + 20c Change (40c - 20c)", 1'b1, 3'b100);

    wait_cycles(1);
    check_outputs("Return to Idle after dispense", 1'b0, 3'b000);

    // -------------------------------------------------------------------------
    // TEST 3: Exact 20 cents via 2 Dimes (10c + 10c = 20c) -> Change = 0c (000)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 3: Two Dimes (10c + 10c = 20c, Change 0c) ---");
    insert_dime();       // Balance: 10c
    check_outputs("After Dime 1 (10c)", 1'b0, 3'b000);

    insert_dime();       // Balance: 20c -> triggers dispense
    check_outputs("Dispense Soda + 0c Change (20c - 20c)", 1'b1, 3'b000);

    wait_cycles(1);
    check_outputs("Return to Idle", 1'b0, 3'b000);

    // -------------------------------------------------------------------------
    // TEST 4: Exact 20 cents via 4 Nickels (4 x 5c = 20c) -> Change = 0c (000)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 4: Four Nickels (4 x 5c = 20c, Change 0c) ---");
    insert_nickle();     // 5c
    check_outputs("Nickle 1 (5c)", 1'b0, 3'b000);

    insert_nickle();     // 10c
    check_outputs("Nickle 2 (10c)", 1'b0, 3'b000);

    insert_nickle();     // 15c
    check_outputs("Nickle 3 (15c)", 1'b0, 3'b000);

    insert_nickle();     // 20c -> dispense
    check_outputs("Dispense Soda + 0c Change (20c - 20c)", 1'b1, 3'b000);

    wait_cycles(1);
    check_outputs("Return to Idle", 1'b0, 3'b000);

    // -------------------------------------------------------------------------
    // TEST 5: Single Quarter (25c) -> Change = 5c (001)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 5: Single Quarter (25c, Change 5c) ---");
    insert_quarter();    // 25c -> dispense
    check_outputs("Dispense Soda + 5c Change (25c - 20c)", 1'b1, 3'b001);

    wait_cycles(1);
    check_outputs("Return to Idle", 1'b0, 3'b000);

    // -------------------------------------------------------------------------
    // TEST 6: Nickle (5c) + Quarter (25c) = 30c -> Change = 10c (010)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 6: Nickle + Quarter (5c + 25c = 30c, Change 10c) ---");
    insert_nickle();     // 5c
    check_outputs("After Nickle (5c)", 1'b0, 3'b000);

    insert_quarter();    // 30c -> dispense
    check_outputs("Dispense Soda + 10c Change (30c - 20c)", 1'b1, 3'b010);

    wait_cycles(1);
    check_outputs("Return to Idle", 1'b0, 3'b000);

    // -------------------------------------------------------------------------
    // TEST 7: Three Dimes (3 x 10c = 30c, with wait cycle)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 7: 10c + 5c + 10c = 25c -> Change 5c (001) ---");
    insert_dime();       // 10c
    check_outputs("Dime (10c)", 1'b0, 3'b000);

    insert_nickle();     // 15c
    check_outputs("Nickle (15c)", 1'b0, 3'b000);

    insert_dime();       // 25c -> dispense
    check_outputs("Dispense Soda + 5c Change (25c - 20c)", 1'b1, 3'b001);

    wait_cycles(2);
    check_outputs("Return to Idle", 1'b0, 3'b000);

    // -------------------------------------------------------------------------
    // SUMMARY
    // -------------------------------------------------------------------------
    $display("\n==================================================================");
    $display("                     TESTBENCH EXECUTION SUMMARY                  ");
    $display("==================================================================");
    $display(" TOTAL CHECKS PASSED : %0d", test_pass_count);
    $display(" TOTAL CHECKS FAILED : %0d", test_fail_count);
    if (test_fail_count == 0) begin
      $display(" >>> ALL TESTS PASSED SUCCESSFULLY! PERFECT COMPLIANCE! <<<");
    end else begin
      $display(" >>> SOME TESTS FAILED! PLEASE REVIEW SIGNALS! <<<");
    end
    $display("==================================================================\n");

    $finish;
  end

endmodule
