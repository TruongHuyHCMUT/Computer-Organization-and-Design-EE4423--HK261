// ============================================================================
// Module: PC
// Description: Program Counter Register
//              Stores current instruction address, updates on clock edge
// ============================================================================
module pc #(
  parameter logic [31:0] RESET_VAL = 32'h8000_0000
)(
  input  logic        i_clk,
  input  logic        i_rstn,
  input  logic [31:0] d,
  output logic [31:0] q
);

  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      q <= RESET_VAL; 
    end else begin
      q <= d;     
    end
  end

endmodule