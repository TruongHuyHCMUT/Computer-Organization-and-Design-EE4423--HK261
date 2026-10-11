// Copyright 2026 Hai Cao - Computer Architecture (HCMUT)
// Design of a Vending Machine Controller
// Adheres to lowRISC SystemVerilog Coding Guidelines:
// - UpperCamelCase for enum values
// - _e suffix for enum types
// - _q and _d suffixes for registered and next-state signals
// - always_comb with unique case and default assignments
// - always_ff containing only register updates

`timescale 1ns / 1ps

module vending_machine (
  input  logic       i_clk,
  input  logic       i_nickle,   // 5 cents coin pulse (1 clock cycle)
  input  logic       i_dime,     // 10 cents coin pulse (1 clock cycle)
  input  logic       i_quarter,  // 25 cents coin pulse (1 clock cycle)
  output logic       o_soda,     // Dispense soda pulse (1 clock cycle)
  output logic [2:0] o_change    // Change code (3-bit data)
);

  // ---------------------------------------------------------------------------
  // State Definitions
  // ---------------------------------------------------------------------------
  // StIdle   : 0 cents accumulated
  // St5      : 5 cents accumulated
  // St10     : 10 cents accumulated
  // St15     : 15 cents accumulated
  // StDisp0  : Total = 20 cents, dispense soda, change = 0 cents  (code 000)
  // StDisp5  : Total = 25 cents, dispense soda, change = 5 cents  (code 001)
  // StDisp10 : Total = 30 cents, dispense soda, change = 10 cents (code 010)
  // StDisp15 : Total = 35 cents, dispense soda, change = 15 cents (code 011)
  // StDisp20 : Total = 40 cents, dispense soda, change = 20 cents (code 100)
  typedef enum logic [3:0] {
    StIdle   = 4'd0,
    St5      = 4'd1,
    St10     = 4'd2,
    St15     = 4'd3,
    StDisp0  = 4'd4,
    StDisp5  = 4'd5,
    StDisp10 = 4'd6,
    StDisp15 = 4'd7,
    StDisp20 = 4'd8
  } state_e;

  state_e state_d;
  state_e state_q = StIdle;

  // ---------------------------------------------------------------------------
  // Combinational Next-State and Output Decode Logic
  // ---------------------------------------------------------------------------
  always_comb begin
    // Default assignments to prevent accidental latch inference
    state_d  = state_q;
    o_soda   = 1'b0;
    o_change = 3'b000;

    unique case (state_q)
      // Balance = 0 cents
      StIdle: begin
        if (i_quarter) begin
          state_d = StDisp5;    // 0 + 25 = 25 cents -> Dispense + Change 5c
        end else if (i_dime) begin
          state_d = St10;       // 0 + 10 = 10 cents
        end else if (i_nickle) begin
          state_d = St5;        // 0 + 5 = 5 cents
        end else begin
          state_d = StIdle;
        end
      end

      // Balance = 5 cents
      St5: begin
        if (i_quarter) begin
          state_d = StDisp10;   // 5 + 25 = 30 cents -> Dispense + Change 10c
        end else if (i_dime) begin
          state_d = St15;       // 5 + 10 = 15 cents
        end else if (i_nickle) begin
          state_d = St10;       // 5 + 5 = 10 cents
        end else begin
          state_d = St5;
        end
      end

      // Balance = 10 cents
      St10: begin
        if (i_quarter) begin
          state_d = StDisp15;   // 10 + 25 = 35 cents -> Dispense + Change 15c
        end else if (i_dime) begin
          state_d = StDisp0;    // 10 + 10 = 20 cents -> Dispense + Change 0c
        end else if (i_nickle) begin
          state_d = St15;       // 10 + 5 = 15 cents
        end else begin
          state_d = St10;
        end
      end

      // Balance = 15 cents
      St15: begin
        if (i_quarter) begin
          state_d = StDisp20;   // 15 + 25 = 40 cents -> Dispense + Change 20c
        end else if (i_dime) begin
          state_d = StDisp5;    // 15 + 10 = 25 cents -> Dispense + Change 5c
        end else if (i_nickle) begin
          state_d = StDisp0;    // 15 + 5 = 20 cents  -> Dispense + Change 0c
        end else begin
          state_d = St15;
        end
      end

      // Dispense states: assert outputs for 1 cycle, then transition to next state
      // Dispense: change 0 cents (code 000)
      StDisp0: begin
        o_soda   = 1'b1;
        o_change = 3'b000;
        if (i_quarter) begin
          state_d = StDisp5;
        end else if (i_dime) begin
          state_d = St10;
        end else if (i_nickle) begin
          state_d = St5;
        end else begin
          state_d = StIdle;
        end
      end

      // Dispense: change 5 cents (code 001)
      StDisp5: begin
        o_soda   = 1'b1;
        o_change = 3'b001;
        if (i_quarter) begin
          state_d = StDisp5;
        end else if (i_dime) begin
          state_d = St10;
        end else if (i_nickle) begin
          state_d = St5;
        end else begin
          state_d = StIdle;
        end
      end

      // Dispense: change 10 cents (code 010)
      StDisp10: begin
        o_soda   = 1'b1;
        o_change = 3'b010;
        if (i_quarter) begin
          state_d = StDisp5;
        end else if (i_dime) begin
          state_d = St10;
        end else if (i_nickle) begin
          state_d = St5;
        end else begin
          state_d = StIdle;
        end
      end

      // Dispense: change 15 cents (code 011)
      StDisp15: begin
        o_soda   = 1'b1;
        o_change = 3'b011;
        if (i_quarter) begin
          state_d = StDisp5;
        end else if (i_dime) begin
          state_d = St10;
        end else if (i_nickle) begin
          state_d = St5;
        end else begin
          state_d = StIdle;
        end
      end

      // Dispense: change 20 cents (code 100)
      StDisp20: begin
        o_soda   = 1'b1;
        o_change = 3'b100;
        if (i_quarter) begin
          state_d = StDisp5;
        end else if (i_dime) begin
          state_d = St10;
        end else if (i_nickle) begin
          state_d = St5;
        end else begin
          state_d = StIdle;
        end
      end

      default: begin
        state_d  = StIdle;
        o_soda   = 1'b0;
        o_change = 3'b000;
      end
    endcase
  end

  // ---------------------------------------------------------------------------
  // Sequential State Register
  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk) begin
    state_q <= state_d;
  end

endmodule
