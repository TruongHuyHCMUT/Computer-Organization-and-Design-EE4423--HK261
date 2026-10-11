module shifter (
    input logic [31:0]  i_data,
    input logic [4:0]   i_shamt,
    input logic [1:0]   i_mode,
    output logic [31:0] o_data
);
    logic   [31:0]  w_sll, w_srl, w_sra;
    SLL sll_inst (
        .A          (i_data),
        .tmp        (i_shamt),
        .Sll_out    (w_sll)
    );

    SRL srl_inst (
        .A          (i_data),
        .tmp        (i_shamt),
        .Srl_out    (w_srl)
    );

    SRA sra_inst (
        .A          (i_data),
        .tmp        (i_shamt),
        .Sra_out    (w_sra)
    );

    always_comb begin
        case(i_mode) 
            2'b00: o_data = w_srl;
            2'b01: o_data = w_sll;
            2'b10: o_data = w_sra;
            2'b11: o_data = i_data;
        endcase 
    end
endmodule 

// Shift Left Logical: fills with zeros on the right
module SLL(
  input  [4:0]  tmp,                 // Shift amount
  input  [31:0] A,                   // Input value
  output [31:0] Sll_out              // Shifted output
);

  logic [31:0] temp_0, temp_1, temp_2, temp_3, temp_4;

  assign temp_0 = (tmp[0]) ? {A[30:0], 1'b0} : A;
  assign temp_1 = (tmp[1]) ? {temp_0[29:0], 2'b0} : temp_0;
  assign temp_2 = (tmp[2]) ? {temp_1[27:0], 4'b0} : temp_1;
  assign temp_3 = (tmp[3]) ? {temp_2[23:0], 8'b0} : temp_2;
  assign temp_4 = (tmp[4]) ? {temp_3[15:0], 16'b0} : temp_3;
  assign Sll_out = temp_4;

endmodule

// Shift Right Logical: fills with zeros on the left
module SRL(
  input  [4:0]  tmp,                 // Shift amount
  input  [31:0] A,                   // Input value
  output [31:0] Srl_out              // Shifted output
);

  logic [31:0] temp_0, temp_1, temp_2, temp_3, temp_4;

  assign temp_0 = (tmp[0]) ? {1'b0, A[31:1]} : A;
  assign temp_1 = (tmp[1]) ? {2'b0, temp_0[31:2]} : temp_0;
  assign temp_2 = (tmp[2]) ? {4'b0, temp_1[31:4]} : temp_1;
  assign temp_3 = (tmp[3]) ? {8'b0, temp_2[31:8]} : temp_2;
  assign temp_4 = (tmp[4]) ? {16'b0, temp_3[31:16]} : temp_3;
  assign Srl_out = temp_4;

endmodule

// Shift Right Arithmetic: sign-extends on the left
module SRA(
  input  [4:0]  tmp,                 // Shift amount
  input  [31:0] A,                   // Input value
  output [31:0] Sra_out              // Shifted output
);

  logic [31:0] temp_0, temp_1, temp_2, temp_3, temp_4;

  assign temp_0 = (tmp[0]) ? {A[31], A[31:1]} : A;
  assign temp_1 = (tmp[1]) ? {{2{A[31]}}, temp_0[31:2]} : temp_0;
  assign temp_2 = (tmp[2]) ? {{4{A[31]}}, temp_1[31:4]} : temp_1;
  assign temp_3 = (tmp[3]) ? {{8{A[31]}}, temp_2[31:8]} : temp_2;
  assign temp_4 = (tmp[4]) ? {{16{A[31]}}, temp_3[31:16]} : temp_3;
  assign Sra_out = temp_4;

endmodule