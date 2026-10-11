// ============================================================================
// Module: i_mem
// Description: Instruction Memory (IMEM) - 2 KiB word-addressed ROM
//              Asynchronous read, preloaded from hex file
//              Contents persist across resets
// ============================================================================
module i_mem(
  input  [31:0] i_addr,              // Byte address input
  output [31:0] o_data               // 32-bit instruction output
);

  // Memory array with FPGA BRAM synthesis attributes
  (* ramstyle = "M10K" *)        // Quartus: Use M10K block RAM
  logic [31:0] mem [0:2047];     // 2048 words × 4 bytes = 8 KiB

  // Load instruction memory from hex file at simulation start
  // Memory contents persist across resets
  initial begin
    //static string test_file = "/home/admink23/projects/...";
    $readmemh("riscv_single.hex", mem);
  end

  // Asynchronous read: convert byte address to word address
  assign o_data = mem[i_addr[12:2]];  // Drop lower 2 bits for word alignment

endmodule

